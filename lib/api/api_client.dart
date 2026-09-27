import 'package:dio/dio.dart';

import '../storage/auth_storage.dart';
import 'api_error_handler.dart';

class ApiClient {
  ApiClient._();

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://hajideligani.ir/api",
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(seconds: 45),
      headers: const {
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      receiveDataWhenStatusError: true,
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = await AuthStorage.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers["Authorization"] = "Bearer $token";
            }
            options.headers["X-Client"] = "karnama-flutter";
            handler.next(options);
          } catch (e) {
            handler.reject(
              DioException(
                requestOptions: options,
                error: e,
                type: DioExceptionType.unknown,
              ),
            );
          }
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            try {
              await AuthStorage.logout();
            } catch (_) {
              // خطای logout نباید باعث خطای دوم شود.
            }
          }
          handler.next(error);
        },
      ),
    );

  static Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  static Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  static Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return dio.patch<T>(
      path,
      data: data,
      options: options,
      cancelToken: cancelToken,
    );
  }

  static ApiErrorHandler errors = ApiErrorHandler();
}
