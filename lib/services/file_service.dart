import 'dart:typed_data';
import 'dart:io';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../offline/offline_store.dart';
import '../offline/offline_sync_service.dart';
import '../utils/app_settings.dart';

class FileService {
  const FileService._();

  static Future<Uint8List?> download(String url, {String? localPath}) async {
    var resolvedLocalPath = localPath;
    if (resolvedLocalPath == null && url.isNotEmpty && await AppSettings.getOfflineEnabled()) {
      try {
        resolvedLocalPath = await OfflineStore.instance.findLocalFileByUrl(
          userId: await OfflineSyncService.currentUserScope(), url: url,
        );
      } catch (_) { /* Fall back to the remote source when cache lookup fails. */ }
    }
    if (resolvedLocalPath != null && resolvedLocalPath.isNotEmpty) {
      final file = File(resolvedLocalPath);
      if (await file.exists()) return await file.readAsBytes();
    }
    final response = await ApiClient.dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    return data == null ? null : Uint8List.fromList(data);
  }
}
