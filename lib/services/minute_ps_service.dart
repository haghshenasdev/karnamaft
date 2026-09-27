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
      filename: json['filename']?.toString() ?? '',
      rawText: json['text']?.toString() ?? '',
    );
  }
}

class MinutePsTextResult {
  final String title;
  final String text;
  final DateTime? date;
  final int? cityId;
  final int? taskId;
  final String? taskName;
  final int? organId;
  final String? cityName;
  final List<String> categoryNames;
  final List<int> categoryIds;

  MinutePsTextResult({
    required this.title,
    required this.text,
    this.date,
    this.cityId,
    this.taskId,
    this.taskName,
    this.organId,
    this.cityName,
    this.categoryNames = const [],
    this.categoryIds = const [],
  });

  factory MinutePsTextResult.fromJson(Map<String, dynamic> json) {
    return MinutePsTextResult(
      title: json['title']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString())
          : null,
      cityId: json['city_id'] is int
          ? json['city_id']
          : int.tryParse('${json['city_id']}'),
      taskId: json['task_id'] is int
          ? json['task_id']
          : int.tryParse('${json['task_id']}'),
      taskName: json['task_name']?.toString(),
      organId: json['organ_id'] is int
          ? json['organ_id']
          : int.tryParse('${json['organ_id']}'),
      cityName: json['city_name']?.toString(),
      categoryNames: (json['category_names'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      categoryIds: (json['category_ids'] as List? ?? [])
          .map((e) => int.tryParse(e.toString()))
          .whereType<int>()
          .toList(),
    );
  }
}

class MinutePsService {
  const MinutePsService();

  /// تحلیل فایل توسط API جدید.
  ///
  /// OCR و تحلیل متن در سمت سرور انجام می‌شود.
  Future<MinutePsTextResult> uploadFile({
    String? filePath,
    Uint8List? bytes,
    String? fileName,
    CancelToken? cancelToken,
  }) async {
    try {
      late MultipartFile file;

      if (bytes != null) {
        file = MultipartFile.fromBytes(
          bytes,
          filename: fileName ?? 'upload.png',
        );
      } else if (filePath != null) {
        file = await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        );
      } else {
        throw Exception('فایلی برای ارسال وجود ندارد');
      }

      final response = await ApiClient.dio.post(
        '/mobile/v1/ai/minutes',
        data: FormData.fromMap({'file': file}),
        options: Options(contentType: 'multipart/form-data'),
        cancelToken: cancelToken,
      );

      final data = response.data is Map<String, dynamic>
          ? response.data['data']
          : null;

      return MinutePsTextResult.fromJson(
        data is Map<String, dynamic> ? data : {},
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        rethrow;
      }

      throw ApiErrorHandler.handle(e);
    }
  }

  /// تحلیل متنی که قبلاً استخراج شده است.
  Future<MinutePsTextResult> analyzeText(
    String text, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/mobile/v1/ai/minutes',
        data: {'text': text},
        cancelToken: cancelToken,
      );

      final data = response.data is Map<String, dynamic>
          ? response.data['data']
          : null;

      return MinutePsTextResult.fromJson(
        data is Map<String, dynamic> ? data : {},
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        rethrow;
      }

      throw ApiErrorHandler.handle(e);
    }
  }

  /// انجام کامل عملیات روی فایل:
  ///
  /// 1. ارسال فایل به API
  /// 2. OCR در سرور
  /// 3. تحلیل متن
  /// 4. استخراج عنوان، تاریخ، شهر، جلسه و دسته‌بندی
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

    return analyzeText(ocrResult.text, cancelToken: cancelToken);
  }
}
