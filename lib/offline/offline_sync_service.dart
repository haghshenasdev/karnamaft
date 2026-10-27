import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../api/api_client.dart';
import '../utils/app_settings.dart';
import 'offline_store.dart';

typedef SyncProgress = void Function(double done, double total, String message);

class OfflineSyncService {
  static const Map<String, String> _resources = {
    'letters': '/mobile/v1/letters',
    'minutes': '/mobile/v1/minutes',
    'contents': '/mobile/v1/contents',
    'projects': '/mobile/v1/projects',
    'tasks': '/mobile/v1/tasks',
    'cartable': '/mobile/v1/cartable',
  };

  static Future<void> sync({required SyncProgress onProgress}) async {
    final root = Directory(await AppSettings.getOfflineRootPath());

    await Directory(p.join(root.path, 'database')).create(recursive: true);

    await Directory(p.join(root.path, 'files')).create(recursive: true);

    const userId = 'current-user';

    var doneResources = 0;
    final totalResources = _resources.length;

    for (final entry in _resources.entries) {
      onProgress(
        doneResources.toDouble(),
        totalResources.toDouble(),
        'دریافت فهرست ${_resourceTitle(entry.key)}...',
      );

      final records = <Map<String, dynamic>>[];

      var page = 1;

      // دریافت صفحات اطلاعات از سرور
      while (page <= 1000) {
        final response = await ApiClient.dio.get<dynamic>(
          entry.value,
          queryParameters: {'page': page, 'per_page': 100},
          options: Options(receiveTimeout: const Duration(seconds: 90)),
        );

        final body = response.data;

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

        records.addAll(
          rows.whereType<Map>().map((item) => Map<String, dynamic>.from(item)),
        );

        if (rows.isEmpty ||
            (lastPage != null && page >= lastPage) ||
            rows.length < 100) {
          break;
        }

        page++;
      }

      // پردازش رکوردها از بزرگ‌ترین شناسه به کوچک‌ترین شناسه
      records.sort(
        (a, b) =>
            _compareIdsDescending(a['id'] ?? a['uuid'], b['id'] ?? b['uuid']),
      );

      var processed = 0;

      for (final record in records) {
        final id = (record['id'] ?? record['uuid'] ?? 'بدون شناسه').toString();

        // نمایش پیشرفت دریافت و ذخیره رکورد جاری
        onProgress(
          doneResources.toDouble() +
              (records.isEmpty ? 0.0 : processed / records.length),
          totalResources.toDouble(),
          '${_resourceTitle(entry.key)} | شناسه $id '
          '(${processed + 1} از ${records.length})؛ '
          'دریافت فایل‌ها و ذخیره اطلاعات',
        );

        // ابتدا فایل‌های مرتبط با رکورد دریافت می‌شوند.
        // سپس اطلاعات رکورد همراه مسیر فایل‌های محلی ذخیره می‌شود.
        await _downloadRecordFiles(root, entry.key, record);

        await OfflineStore.instance.cacheRecords(
          resource: entry.key,
          userId: userId,
          records: [record],
        );

        processed++;
      }

      doneResources++;

      onProgress(
        doneResources.toDouble(),
        totalResources.toDouble(),
        '${_resourceTitle(entry.key)}: '
        '${records.length} رکورد ذخیره شد',
      );
    }

    await _saveSyncTime();

    onProgress(
      totalResources.toDouble(),
      totalResources.toDouble(),
      'همگام‌سازی اطلاعات و فایل‌ها کامل شد',
    );
  }

  /// مرتب‌سازی شناسه‌ها به‌صورت نزولی
  static int _compareIdsDescending(dynamic left, dynamic right) {
    final a = int.tryParse('${left ?? ''}');
    final b = int.tryParse('${right ?? ''}');

    if (a != null && b != null) {
      return b.compareTo(a);
    }

    return '${right ?? ''}'.compareTo('${left ?? ''}');
  }

  /// عنوان فارسی منابع اطلاعاتی
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

  /// دریافت فایل‌های وابسته به هر رکورد و ذخیره محلی آن‌ها
  static Future<void> _downloadRecordFiles(
    Directory root,
    String type,
    Map<String, dynamic> record,
  ) async {
    final dateText =
        (record['date'] ??
                record['created_at'] ??
                record['registered_at'] ??
                '')
            .toString();

    final date = DateTime.tryParse(dateText);

    final year = date == null ? 'unknown' : date.year.toString();

    final month = date == null
        ? 'unknown'
        : date.month.toString().padLeft(2, '0');

    final directory = Directory(p.join(root.path, 'files', type, year, month));

    await directory.create(recursive: true);

    // پشتیبانی از فیلدهای قدیمی فایل و فیلد files
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
        candidates.add(Map<String, dynamic>.from(value));
      }
    }

    final rawFiles = record['files'];

    if (rawFiles is List) {
      for (final item in rawFiles) {
        if (item is Map &&
            item['url'] is String &&
            (item['url'] as String).trim().isNotEmpty) {
          candidates.add(Map<String, dynamic>.from(item));
        }
      }
    }

    final savedFiles = <Map<String, dynamic>>[];
    final seen = <String>{};

    for (final item in candidates) {
      final rawUrl = (item['url'] ?? item['download_url'] ?? '')
          .toString()
          .trim();

      if (rawUrl.isEmpty) continue;

      final url = rawUrl.startsWith('http')
          ? rawUrl
          : rawUrl.startsWith('/')
          ? '${ApiClient.dio.options.baseUrl}$rawUrl'
          : '';

      if (url.isEmpty || !seen.add(url)) continue;

      try {
        final uri = Uri.parse(url);
        final fromUrl = p.basename(uri.path);

        final suppliedName =
            (item['title'] ?? item['name'] ?? item['file_name'] ?? '')
                .toString()
                .trim();

        final extension = (item['extension'] ?? '')
            .toString()
            .trim()
            .replaceFirst(RegExp(r'^\.'), '');

        var basename = suppliedName.isEmpty ? fromUrl : suppliedName;

        if (basename.isEmpty || basename == '/' || basename == '.') {
          basename = 'record_${record['id'] ?? 'file'}_${savedFiles.length}';
        }

        if (extension.isNotEmpty && p.extension(basename).isEmpty) {
          basename = '$basename.$extension';
        }

        // جلوگیری از ورود نام فایل به مسیرهای دیگر
        basename = p
            .basename(basename)
            .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

        final target = File(p.join(directory.path, basename));

        if (!await target.exists() || await target.length() == 0) {
          final response = await ApiClient.dio.get<List<int>>(
            url,
            options: Options(
              responseType: ResponseType.bytes,
              receiveTimeout: const Duration(seconds: 90),
            ),
          );

          if (response.data == null || response.data!.isEmpty) {
            continue;
          }

          await target.writeAsBytes(response.data!, flush: true);
        }

        savedFiles.add({...item, 'url': rawUrl, 'local_path': target.path});
      } catch (_) {
        // در صورت خطای دریافت، اطلاعات فایل حفظ می‌شود.
        savedFiles.add({...item, 'url': rawUrl, 'download_failed': true});
      }
    }

    if (rawFiles is List) {
      record['files'] = savedFiles;
    }

    // نگهداری مسیر فایل‌های ذخیره‌شده برای استفاده آفلاین
    if (savedFiles.isNotEmpty) {
      record['offline_files'] = savedFiles;
    }
  }

  /// ذخیره زمان آخرین همگام‌سازی
  static Future<void> _saveSyncTime() async {
    await AppSettings.setOfflineLastSync(DateTime.now());
  }
}
