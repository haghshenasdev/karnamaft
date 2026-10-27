import 'dart:io';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../api/api_client.dart';
import '../utils/app_settings.dart';
import 'offline_store.dart';

/// Progress is expressed in resource units so the existing settings UI can
/// continue to calculate `done / total`, while fractional progress is shown
/// within the current resource.
typedef SyncProgress = void Function(
  double done,
  double total,
  String message,
);

class OfflineSyncService {
  static const Map<String, String> _resources = {
    'letters': '/mobile/v1/letters',
    'minutes': '/mobile/v1/minutes',
    'contents': '/mobile/v1/contents',
    'projects': '/mobile/v1/projects',
    'tasks': '/mobile/v1/tasks',
    'cartable': '/mobile/v1/cartable',
  };

  // Larger pages reduce HTTP round trips. If the backend caps per_page,
  // pagination still works with the actual number of rows returned.
  static const int _pageSize = 200;
  static const int _cacheBatchSize = 250;
  static const int _downloadGroupSize = 20;

  // A small fixed worker pool is safer for both Android and Windows than
  // starting a download Future for every attachment at once.
  static const int _parallelRecordDownloads = 2;
  static const int _maxHttpRetries = 5;

  static bool _pauseRequested = false;
  static bool _isSyncing = false;
  static bool get isSyncing => _isSyncing;
  static bool get isPauseRequested => _pauseRequested;

  /// Requests a safe pause. Current HTTP/file operation is allowed to finish.
  static void requestPause() {
    _pauseRequested = true;
  }

  static Future<void> sync({required SyncProgress onProgress}) async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      await _syncInternal(onProgress: onProgress);
    } finally {
      _isSyncing = false;
    }
  }

  static Future<void> _syncInternal({required SyncProgress onProgress}) async {
    _pauseRequested = false;
    final root = Directory(await AppSettings.getOfflineRootPath());
    await Directory(p.join(root.path, 'database')).create(recursive: true);
    await Directory(p.join(root.path, 'files')).create(recursive: true);

    const userId = 'current-user';
    var doneResources = 0;
    final totalResources = _resources.length;
    final checkpoint = await OfflineStore.instance.getSyncCheckpoint();
    final startResourceIndex = (checkpoint ?? 0).clamp(0, totalResources);
    final entries = _resources.entries.toList();
    doneResources = startResourceIndex;

    for (var resourceIndex = startResourceIndex; resourceIndex < entries.length; resourceIndex++) {
      final entry = entries[resourceIndex];
      await OfflineStore.instance.saveSyncCheckpoint(resourceIndex);
      final resource = entry.key;
      final endpoint = entry.value;
      final records = <Map<String, dynamic>>[];
      var page = 1;

      onProgress(
        doneResources.toDouble(),
        totalResources.toDouble(),
        'دریافت فهرست ${_resourceTitle(resource)} از جدیدترین شناسه‌ها...',
      );

      // The API used by the app accepts `sort: -id` in its list endpoints.
      // Cache each page immediately so the newest records become available
      // before the older pages and attachments have all finished.
      while (page <= 1000) {
        final response = await _getWithRetry<dynamic>(
          endpoint,
          queryParameters: {
            'page': page,
            'per_page': _pageSize,
            'sort': '-id',
          },
          options: Options(
            receiveTimeout: const Duration(seconds: 90),
          ),
        );

        final parsed = _parsePage(response.data);
        final pageRecords = parsed.records;
        if (pageRecords.isEmpty) break;

        // Sort within the page too, in case the server returns an unexpected
        // order. The server-side sort is what keeps page order newest-first.
        pageRecords.sort(
          (a, b) => _compareIdsDescending(
            a['id'] ?? a['uuid'],
            b['id'] ?? b['uuid'],
          ),
        );

        records.addAll(pageRecords);

        // Save metadata right away, before downloading any attachments.
        await OfflineStore.instance.cacheRecords(
          resource: resource,
          userId: userId,
          records: pageRecords,
        );

        final double pageFraction = (parsed.lastPage != null && parsed.lastPage! > 0
                ? (page / parsed.lastPage!).clamp(0.0, 1.0)
                : (page / (page + 4.0)).clamp(0.0, 0.95))
            .toDouble();
        onProgress(
          (doneResources + 0.45 * pageFraction).toDouble(),
          totalResources.toDouble(),
          '${_resourceTitle(resource)} | دریافت و ذخیره اطلاعات صفحه $page؛ '
              '${records.length} رکورد تا این مرحله',
        );

        if (_pauseRequested) {
          await OfflineStore.instance.saveSyncCheckpoint(resourceIndex);
          onProgress(doneResources.toDouble(), totalResources.toDouble(),
              'توقف شد؛ نقطه ادامه ذخیره شد. برای ادامه، «ادامه همگام‌سازی» را بزنید.');
          return;
        }

        if ((parsed.lastPage != null && page >= parsed.lastPage!) ||
            pageRecords.length < _pageSize) {
          break;
        }
        page++;
      }

      // Ensure globally descending order before processing attachments.
      records.sort(
        (a, b) => _compareIdsDescending(
          a['id'] ?? a['uuid'],
          b['id'] ?? b['uuid'],
        ),
      );

      var completedRecords = 0;
      final totalRecords = records.length;

      // Process small groups. Within each group, up to four records download
      // their attachments concurrently; updated metadata is then batch-saved.
      for (var start = 0; start < records.length; start += _downloadGroupSize) {
        final end = (start + _downloadGroupSize < records.length)
            ? start + _downloadGroupSize
            : records.length;
        final chunk = records.sublist(start, end);
        var nextIndex = 0;

        Future<void> worker() async {
          while (true) {
            final index = nextIndex++;
            if (index >= chunk.length) return;

            final record = chunk[index];
            final id = (record['id'] ?? record['uuid'] ?? 'بدون شناسه').toString();
            onProgress(
              doneResources +
                  0.45 +
                  (totalRecords == 0
                      ? 0.0
                      : 0.54 * completedRecords / totalRecords),
              totalResources.toDouble(),
              '${_resourceTitle(resource)} | شناسه $id؛ دریافت پیوست‌ها '
                  '($completedRecords از $totalRecords)',
            );

            await _downloadRecordFiles(root, resource, record);
            completedRecords++;
            if (_pauseRequested) return;
          }
        }

        final workerCount = chunk.length < _parallelRecordDownloads
            ? chunk.length
            : _parallelRecordDownloads;
        await Future.wait(
          List<Future<void>>.generate(workerCount, (_) => worker()),
        );

        // Batch-update the records with local attachment paths/status.
        await OfflineStore.instance.cacheRecords(
          resource: resource,
          userId: userId,
          records: chunk,
        );

        if (_pauseRequested) {
          await OfflineStore.instance.saveSyncCheckpoint(resourceIndex);
          onProgress(doneResources.toDouble(), totalResources.toDouble(),
              'توقف شد؛ اطلاعات ذخیره شد و نقطه ادامه ثبت شد.');
          return;
        }
      }

      doneResources++;
      await OfflineStore.instance.saveSyncCheckpoint(resourceIndex + 1);
      onProgress(
        doneResources.toDouble(),
        totalResources.toDouble(),
        '${_resourceTitle(resource)}: ${records.length} رکورد پردازش شد',
      );
    }

    await _saveSyncTime();
    await OfflineStore.instance.clearSyncCheckpoint();
    onProgress(
      totalResources.toDouble(),
      totalResources.toDouble(),
      'همگام‌سازی اطلاعات و فایل‌ها کامل شد',
    );
  }

  static _ParsedPage _parsePage(dynamic body) {
    List<dynamic> rows = [];
    int? lastPage;

    if (body is Map) {
      final data = body['data'];
      if (data is List) {
        rows = data;
      } else if (data is Map && data['data'] is List) {
        rows = data['data'] as List;
        lastPage = int.tryParse('${data['last_page'] ?? ''}');
      }

      final meta = body['meta'];
      lastPage ??= int.tryParse(
        '${body['last_page'] ?? (meta is Map ? meta['last_page'] : '') ?? ''}',
      );
    } else if (body is List) {
      rows = body;
    }

    final records = rows
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    return _ParsedPage(records, lastPage);
  }

  static int _compareIdsDescending(dynamic left, dynamic right) {
    final a = int.tryParse('${left ?? ''}');
    final b = int.tryParse('${right ?? ''}');
    if (a != null && b != null) return b.compareTo(a);
    return '${right ?? ''}'.compareTo('${left ?? ''}');
  }

  static String _resourceTitle(String key) {
    const titles = <String, String>{
      'letters': 'نامه‌ها',
      'minutes': 'صورت‌جلسه‌ها',
      'contents': 'محتواها',
      'projects': 'پروژه‌ها',
      'tasks': 'وظایف',
      'cartable': 'کارتابل',
    };
    return titles[key] ?? key;
  }

  static Future<void> _downloadRecordFiles(
    Directory root,
    String type,
    Map<String, dynamic> record,
  ) async {
    final dateText = (record['date'] ??
            record['created_at'] ??
            record['registered_at'] ??
            '')
        .toString();
    final date = DateTime.tryParse(dateText);
    final jalali = date == null ? null : _gregorianToJalali(date.year, date.month, date.day);
    final year = jalali == null ? 'unknown' : jalali.$1.toString();
    final month = jalali == null ? 'unknown' : jalali.$2.toString().padLeft(2, '0');
    final day = jalali == null ? 'unknown' : jalali.$3.toString().padLeft(2, '0');
    final directory = Directory(p.join(root.path, 'files', type, year, month, day));
    await directory.create(recursive: true);

    final candidates = <Map<String, dynamic>>[];
    for (final key in [
      'file_url',
      'download_url',
      'attachment_url',
      'document_url',
      'file_path',
      'attachment',
    ]) {
      final value = record[key];
      if (value is String && value.trim().isNotEmpty) {
        candidates.add({
          'url': value.trim(),
          'name': 'record_${record['id'] ?? 'file'}',
        });
      } else if (value is Map && value['url'] is String) {
        candidates.add({
          ...Map<String, dynamic>.from(value),
        });
      }
    }

    final rawFiles = record['files'];
    if (rawFiles is List) {
      for (var i = 0; i < rawFiles.length; i++) {
        final item = rawFiles[i];
        if (item is Map && item['url'] is String) {
          candidates.add({
            ...Map<String, dynamic>.from(item),
          });
        }
      }
    }

    final savedFiles = <Map<String, dynamic>>[];
    final seen = <String>{};
    var fileIndex = 0;

    for (final item in candidates) {
      final rawUrl = (item['url'] ?? item['download_url'] ?? '').toString().trim();
      if (rawUrl.isEmpty) continue;

      final url = _absoluteUrl(rawUrl);
      if (url.isEmpty || !seen.add(url)) continue;

      try {
        final uri = Uri.parse(url);
        final fromUrl = p.basename(uri.path);
        final suppliedName = (item['title'] ?? item['name'] ?? item['file_name'] ?? '')
            .toString()
            .trim();
        final extension = (item['extension'] ?? '')
            .toString()
            .trim()
            .replaceFirst(RegExp(r'^\.'), '');

        var basename = suppliedName.isEmpty ? fromUrl : suppliedName;
        if (basename.isEmpty || basename == '/' || basename == '.') {
          basename = 'file_${record['id'] ?? 'record'}_$fileIndex';
        }
        if (extension.isNotEmpty && p.extension(basename).isEmpty) {
          basename = '$basename.$extension';
        }
        basename = p.basename(basename).replaceAll(
          RegExp(r'[<>:"/\\|?*]'),
          '_',
        );

        // Prefix the record ID to avoid collisions when different records
        // contain files with the same original filename.
        final recordId = (record['id'] ?? record['uuid'] ?? 'record').toString();
        final safeRecordId = recordId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        final target = File(p.join(directory.path, '${safeRecordId}_$basename'));

        if (!await target.exists() || await target.length() == 0) {
          final response = await _getWithRetry<List<int>>(
            url,
            options: Options(
              responseType: ResponseType.bytes,
              receiveTimeout: const Duration(seconds: 90),
            ),
          );
          if (response.data == null || response.data!.isEmpty) {
            savedFiles.add({...item, 'url': rawUrl, 'download_failed': true});
            fileIndex++;
            continue;
          }
          await target.writeAsBytes(response.data!, flush: true);
        }

        savedFiles.add({
          ...item,
          'url': rawUrl,
          'local_path': target.path,
          'download_failed': false,
        });
      } catch (_) {
        savedFiles.add({
          ...item,
          'url': rawUrl,
          'download_failed': true,
        });
      }
      fileIndex++;
    }

    // Keep original file entries, enriching them with local paths where a
    // matching download succeeded instead of dropping metadata without URLs.
    if (rawFiles is List) {
      final enriched = <dynamic>[];
      for (final original in rawFiles) {
        if (original is! Map) {
          enriched.add(original);
          continue;
        }
        final originalMap = Map<String, dynamic>.from(original);
        final originalUrl = (originalMap['url'] ?? originalMap['download_url'] ?? '').toString().trim();
        final saved = savedFiles.where((f) =>
            (f['url'] ?? f['download_url'] ?? '').toString().trim() == originalUrl).firstOrNull;
        enriched.add(saved == null ? originalMap : {...originalMap, ...saved});
      }
      record['files'] = enriched;
    }

    if (savedFiles.isNotEmpty) {
      record['offline_files'] = savedFiles;
    }
  }

  static String _absoluteUrl(String rawUrl) {
    if (rawUrl.startsWith('https://') || rawUrl.startsWith('http://')) {
      return rawUrl;
    }
    final baseUrl = ApiClient.dio.options.baseUrl;
    if (baseUrl.isEmpty) return '';
    try {
      if (rawUrl.startsWith('/')) {
        final base = Uri.parse(baseUrl);
        return base.replace(path: rawUrl, query: null, fragment: null).toString();
      }
      return Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/').resolve(rawUrl).toString();
    } catch (_) {
      return '';
    }
  }


  /// Retries rate limits and temporary server errors with exponential backoff.
  /// Retry-After is honored when supplied by the server.
  static Future<Response<T>> _getWithRetry<T>(
    String url, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    var attempt = 0;
    while (true) {
      try {
        return await ApiClient.dio.get<T>(
          url,
          queryParameters: queryParameters,
          options: options,
        );
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        final retryable = status == 429 || status == 408 ||
            (status != null && status >= 500) ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError;
        if (!retryable || attempt >= _maxHttpRetries) rethrow;

        final retryAfter = e.response?.headers.value('retry-after');
        final seconds = int.tryParse(retryAfter ?? '');
        final delay = seconds != null
            ? Duration(seconds: seconds.clamp(1, 60))
            : Duration(seconds: 1 << attempt);
        await Future<void>.delayed(delay);
        attempt++;
      }
    }
  }

  /// Converts a Gregorian calendar date to Jalali without an extra dependency.
  static (int, int, int) _gregorianToJalali(int gy, int gm, int gd) {
    const gDaysInMonth = <int>[31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    const jDaysInMonth = <int>[31, 31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 29];
    final g = <int>[gy, gm, gd];
    final gy2 = gy + (gm > 2 ? 1 : 0);
    var days = 355666 + 365 * gy +
        ((gy2 + 3) ~/ 4) -
        ((gy2 + 99) ~/ 100) +
        ((gy2 + 399) ~/ 400) +
        gd;
    for (var i = 0; i < gm - 1; i++) {
      days += gDaysInMonth[i];
    }
    if (gm > 2 && _isGregorianLeap(gy)) days++;
    var jy = -1595 + 33 * (days ~/ 12053);
    days %= 12053;
    jy += 4 * (days ~/ 1461);
    days %= 1461;
    if (days > 365) {
      jy += (days - 1) ~/ 365;
      days = (days - 1) % 365;
    }
    var jm = 1;
    while (jm <= 11 && days >= jDaysInMonth[jm - 1]) {
      days -= jDaysInMonth[jm - 1];
      jm++;
    }
    final jd = days + 1;
    return (jy, jm, jd);
  }

  static bool _isGregorianLeap(int year) =>
      year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);

  static Future<void> _saveSyncTime() async {
    await AppSettings.setOfflineLastSync(DateTime.now());
  }
}

class _ParsedPage {
  final List<Map<String, dynamic>> records;
  final int? lastPage;

  const _ParsedPage(this.records, this.lastPage);
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
