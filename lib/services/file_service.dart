import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../api/api_client.dart';

class FileService {
  const FileService._();

  static Future<Uint8List?> download(String url) async {
    final response = await ApiClient.dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    return data == null ? null : Uint8List.fromList(data);
  }
}
