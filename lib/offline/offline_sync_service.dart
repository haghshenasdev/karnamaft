import 'dart:io';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path/path.dart' as p;
import '../api/api_client.dart';
import '../utils/app_settings.dart';
import 'offline_store.dart';

typedef SyncProgress = void Function(int done, int total, String message);

class OfflineSyncService {
  static const _resources = <String, String>{
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
    var done = 0;
    final total = _resources.length;
    for (final entry in _resources.entries) {
      onProgress(done, total, 'دریافت ${entry.key}');
      final records = <Map<String, dynamic>>[];
      var page = 1;
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
          lastPage ??= int.tryParse('${body['last_page'] ?? body['meta']?['last_page'] ?? ''}');
        } else if (body is List) {
          rows = body;
        }
        records.addAll(rows.whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
        if (rows.isEmpty || (lastPage != null && page >= lastPage) || rows.length < 100) break;
        page++;
      }
      await _downloadRecordFiles(root, entry.key, records, onProgress, done, total);
      await OfflineStore.instance.cacheRecords(
        resource: entry.key,
        userId: userId,
        records: records,
      );
      done++;
      onProgress(done, total, '${entry.key}: ${records.length} رکورد ذخیره شد');
    }
    await _saveSyncTime();
    onProgress(total, total, 'همگام‌سازی اطلاعات کامل شد');
  }

  static Future<void> _downloadRecordFiles(
    Directory root,
    String type,
    List<Map<String, dynamic>> records,
    SyncProgress onProgress,
    int done,
    int total,
  ) async {
    var downloaded = 0;
    for (final record in records) {
      final dateText = (record['date'] ?? record['created_at'] ?? record['registered_at'] ?? '').toString();
      final date = DateTime.tryParse(dateText);
      final year = date == null ? 'unknown' : date.year.toString();
      final month = date == null ? 'unknown' : date.month.toString().padLeft(2, '0');
      final candidates = <String>[];
      for (final key in ['file_url', 'download_url', 'attachment_url', 'document_url', 'file_path', 'attachment']) {
        final value = record[key];
        if (value is String && value.startsWith('http')) candidates.add(value);
        if (value is Map && value['url'] is String && (value['url'] as String).startsWith('http')) {
          candidates.add(value['url'] as String);
        }
      }
      for (final url in candidates.toSet()) {
        try {
          final uri = Uri.parse(url);
          final basename = p.basename(uri.path).isEmpty ? 'file_${record['id'] ?? downloaded}' : p.basename(uri.path);
          final directory = Directory(p.join(root.path, 'files', type, year, month));
          await directory.create(recursive: true);
          final target = File(p.join(directory.path, basename));
          if (!await target.exists()) {
            final response = await ApiClient.dio.get<List<int>>(
              url,
              options: Options(responseType: ResponseType.bytes, receiveTimeout: const Duration(seconds: 90)),
            );
            if (response.data != null) await target.writeAsBytes(response.data!, flush: true);
          }
          downloaded++;
          onProgress(done, total, 'دریافت فایل‌های $type: $downloaded');
        } catch (_) {
          // Keep metadata cached; a failed attachment can be retried next sync.
        }
      }
    }
  }

  static Future<void> _saveSyncTime() async {
    // Sync time is kept in SharedPreferences by AppSettings.
    await AppSettings.setOfflineLastSync(DateTime.now());
  }
}
