import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Object? cause;
  final bool retryable;

  const ApiException(
    this.message, {
    this.statusCode,
    this.cause,
    this.retryable = false,
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isServerError => statusCode != null && statusCode! >= 500;

  /// گزارش قابل‌فهم برای کاربر؛ مسیر درخواست و کد HTTP برای عیب‌یابی
  /// نمایش داده می‌شوند، اما توکن و هدرهای احراز هویت هرگز نمایش داده نمی‌شوند.
  @override
  String toString() {
    final details = <String>[];
    if (statusCode != null) details.add('HTTP $statusCode');
    if (cause is DioException) {
      final request = (cause as DioException).requestOptions;
      details.add('${request.method} ${request.path}');
    }
    return details.isEmpty ? message : '$message\\nجزئیات: ${details.join(' | ')}';
  }
}
