import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_error_handler.dart';

class MinutePsResult {
  final String filename;
  final String rawText;

  MinutePsResult({required this.filename, required this.rawText});

  factory MinutePsResult.fromJson(Map<String, dynamic> json) {
    return MinutePsResult(
      filename: json["filename"] ?? "",
      rawText: json["text"] ?? "",
    );
  }
}

class MinutePsTextResult {
  final String title;
  final String text;

  MinutePsTextResult({required this.title, required this.text});

  factory MinutePsTextResult.fromJson(Map<String, dynamic> json) {
    return MinutePsTextResult(
      title: json["title"] ?? "",
      text: json["text"] ?? "",
    );
  }
}

class MinutePsService {
  const MinutePsService();

  /// ارسال فایل عکس و دریافت OCR
  Future<MinutePsResult> uploadFile({
    String? filePath,
    Uint8List? bytes,
    String? fileName,
    CancelToken? cancelToken,
  }) async {
    try {
      MultipartFile file;

      if (kIsWeb) {
        file = MultipartFile.fromBytes(
          bytes!,
          filename: fileName ?? "upload.jpg",
        );
      } else {
        file = await MultipartFile.fromFile(
          filePath!,
          filename: filePath.split("/").last,
        );
      }

      final formData = FormData.fromMap({"file": file});

      final response = await ApiClient.dio.post(
        "/minute_ps",

        data: formData,

        options: Options(contentType: "multipart/form-data"),

        cancelToken: cancelToken,
      );

      if (response.data["success"] == true) {
        return MinutePsResult.fromJson(response.data["data"]);
      }

      throw Exception("OCR انجام نشد");
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw e;
      }

      throw ApiErrorHandler.handle(e);
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  /// ارسال متن OCR برای اصلاح و استخراج عنوان
  Future<MinutePsTextResult> analyzeText(
    String text, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        "/minute_ps_text",

        data: {"text": text},

        cancelToken: cancelToken,
      );

      if (response.data["success"] == true) {
        return MinutePsTextResult.fromJson(response.data["data"]);
      }

      throw Exception("تحلیل متن انجام نشد");
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw e;
      }

      throw ApiErrorHandler.handle(e);
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  /// انجام کامل عملیات
  /// 1- OCR فایل
  /// 2- اصلاح متن و گرفتن عنوان

  Future<MinutePsTextResult> processFile({
    String? filePath,
    Uint8List? bytes,
    String? fileName,
    CancelToken? cancelToken,
  }) async {
    final ocrResult = await uploadFile(
      filePath: filePath,
      bytes: bytes,
      fileName: fileName,
      cancelToken: cancelToken,
    );

    return analyzeText(ocrResult.rawText, cancelToken: cancelToken);
  }
}
