import 'dart:io';

import 'package:dio/dio.dart';

import 'api_exception.dart';

class ApiErrorHandler {
  static ApiException handle(Object error) {
    //-----------------------------------------
    // Dio Error
    //-----------------------------------------

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return const ApiException("مهلت اتصال به سرور به پایان رسید.");

        case DioExceptionType.sendTimeout:
          return const ApiException("ارسال اطلاعات با خطا مواجه شد.");

        case DioExceptionType.receiveTimeout:
          return const ApiException("سرور در زمان مناسب پاسخ نداد.");

        case DioExceptionType.connectionError:
          return const ApiException("اتصال به اینترنت برقرار نیست.");

        case DioExceptionType.cancel:
          return const ApiException("درخواست لغو شد.");

        case DioExceptionType.badCertificate:
          return const ApiException("گواهی SSL معتبر نیست.");

        case DioExceptionType.badResponse:
          return _handleStatus(
            error.response?.statusCode,
            error.response?.data,
          );

        case DioExceptionType.unknown:
          if (error.error is SocketException) {
            return const ApiException("اتصال اینترنت برقرار نیست.");
          }

          return const ApiException("خطای ناشناخته رخ داده است.");
        case DioExceptionType.transformTimeout:
          // TODO: Handle this case.
          throw UnimplementedError();
      }
    }

    //-----------------------------------------
    // Unknown
    //-----------------------------------------

    return ApiException(error.toString());
  }

  static ApiException _handleStatus(int? code, dynamic body) {
    switch (code) {
      case 400:
        return ApiException(body?["message"] ?? "درخواست نامعتبر است.");

      case 401:
        return ApiException(
          body?["message"] ?? "نام کاربری یا رمز عبور اشتباه است.",
        );

      case 403:
        return const ApiException("شما مجوز انجام این عملیات را ندارید.");

      case 404:
        return const ApiException("اطلاعات مورد نظر پیدا نشد.");

      case 422:
        return ApiException(body?["message"] ?? "اطلاعات وارد شده معتبر نیست.");

      case 500:
        return const ApiException("خطای داخلی سرور.");

      default:
        return ApiException(body?["message"] ?? "خطای ناشناخته.");
    }
  }
}
