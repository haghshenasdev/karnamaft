import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import 'api_exception.dart';

class ApiErrorHandler {
  static ApiException handle(Object error) {
    if (error is ApiException) return error;

    if (error is DioException) {
      final code = error.response?.statusCode;

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return ApiException(
            'ارتباط با سرور برقرار نشد. لطفاً اتصال اینترنت را بررسی کنید.',
            statusCode: code,
            cause: error,
            retryable: true,
          );

        case DioExceptionType.sendTimeout:
          return ApiException(
            'ارسال اطلاعات بیش از حد طول کشید. دوباره تلاش کنید.',
            statusCode: code,
            cause: error,
            retryable: true,
          );

        case DioExceptionType.receiveTimeout:
          return ApiException(
            'سرور در زمان مناسب پاسخ نداد. لطفاً دوباره تلاش کنید.',
            statusCode: code,
            cause: error,
            retryable: true,
          );

        case DioExceptionType.connectionError:
          return ApiException(
            'اتصال اینترنت برقرار نیست یا سرور در دسترس نیست.',
            statusCode: code,
            cause: error,
            retryable: true,
          );

        case DioExceptionType.cancel:
          return ApiException(
            'درخواست لغو شد.',
            statusCode: code,
            cause: error,
          );

        case DioExceptionType.badCertificate:
          return ApiException(
            'گواهی امنیتی سرور معتبر نیست.',
            statusCode: code,
            cause: error,
          );

        case DioExceptionType.badResponse:
          return _handleStatus(code, error.response?.data);

        case DioExceptionType.unknown:
          if (error.error is SocketException ||
              error.error is HandshakeException) {
            return ApiException(
              'اتصال اینترنت برقرار نیست یا سرور قابل دسترسی نیست.',
              statusCode: code,
              cause: error,
              retryable: true,
            );
          }

          return ApiException(
            'ارتباط با سرور با خطای غیرمنتظره مواجه شد.',
            statusCode: code,
            cause: error,
          );

        case DioExceptionType.transformTimeout:
          return ApiException(
            'پردازش پاسخ سرور بیش از حد طول کشید.',
            statusCode: code,
            cause: error,
            retryable: true,
          );
      }
    }

    return ApiException(
      'خطای غیرمنتظره‌ای رخ داد. لطفاً دوباره تلاش کنید.',
      cause: error,
    );
  }

  static ApiException _handleStatus(int? code, dynamic body) {
    final message = _extractMessage(body);

    switch (code) {
      case 400:
        return ApiException(message ?? 'درخواست نامعتبر است.', statusCode: code);
      case 401:
        return ApiException(
          message ?? 'نشست کاربری شما منقضی شده است. دوباره وارد شوید.',
          statusCode: code,
        );
      case 403:
        return ApiException(
          message ?? 'شما مجوز انجام این عملیات را ندارید.',
          statusCode: code,
        );
      case 404:
        return ApiException(
          message ?? 'اطلاعات مورد نظر پیدا نشد.',
          statusCode: code,
        );
      case 409:
        return ApiException(
          message ?? 'این عملیات با وضعیت فعلی اطلاعات سازگار نیست.',
          statusCode: code,
        );
      case 413:
        return ApiException(
          message ?? 'حجم فایل یا اطلاعات ارسالی بیش از حد مجاز است.',
          statusCode: code,
        );
      case 422:
        return ApiException(
          message ?? 'اطلاعات وارد شده معتبر نیست.',
          statusCode: code,
        );
      case 429:
        return ApiException(
          message ?? 'تعداد درخواست‌ها زیاد است. چند لحظه بعد دوباره تلاش کنید.',
          statusCode: code,
          retryable: true,
        );
      case 500:
        return ApiException(
          message ?? 'خطای داخلی سرور رخ داده است.',
          statusCode: code,
        );
      case 502:
      case 503:
      case 504:
        return ApiException(
          message ?? 'سرور موقتاً در دسترس نیست. دوباره تلاش کنید.',
          statusCode: code,
          retryable: true,
        );
      default:
        return ApiException(
          message ?? 'خطای سرور (${code ?? 'نامشخص'}) رخ داده است.',
          statusCode: code,
        );
    }
  }

  static String? _extractMessage(dynamic body) {
    if (body == null) return null;

    if (body is Map) {
      for (final key in const ['message', 'error', 'detail']) {
        final value = body[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }

      final errors = body['errors'];
      if (errors is Map) {
        final parts = <String>[];
        for (final value in errors.values) {
          if (value is List) {
            parts.addAll(value.map((e) => e.toString()));
          } else if (value != null) {
            parts.add(value.toString());
          }
        }
        if (parts.isNotEmpty) return parts.join('\n');
      }
    }

    if (body is String && body.trim().isNotEmpty) {
      final value = body.trim();
      if (value.startsWith('<')) return null; // HTML error page
      try {
        final decoded = jsonDecode(value);
        return _extractMessage(decoded);
      } catch (_) {
        return value.length > 300 ? null : value;
      }
    }

    return null;
  }
}
