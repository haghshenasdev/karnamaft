import 'package:dio/dio.dart';

import '../storage/auth_storage.dart';
import '../offline/offline_store.dart';
import '../utils/app_settings.dart';
import 'dart:convert';
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
    )..interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) async {
          try {
            final request = response.requestOptions;
            if (request.method.toUpperCase() == 'GET' &&
                await AppSettings.getOfflineEnabled() &&
                response.statusCode != null &&
                response.statusCode! >= 200 &&
                response.statusCode! < 300) {
              final token = await AuthStorage.getToken();
              if (token != null && token.isNotEmpty) {
                final key = _offlineCacheKey(request);
                await OfflineStore.instance.cacheHttpResponse(
                  key: key,
                  userScope: token.hashCode.toString(),
                  payload: response.data,
                );
              }
            }
          } catch (_) {
            // Caching failure must never fail a successful online request.
          }
          handler.next(response);
        },
        onError: (error, handler) async {
          final status = error.response?.statusCode;
          final canFallback = status == null || status >= 500;
          final request = error.requestOptions;
          if (request.method.toUpperCase() == 'GET' &&
              canFallback &&
              await AppSettings.getOfflineEnabled()) {
            try {
              final token = await AuthStorage.getToken();
              if (token != null && token.isNotEmpty) {
                final cached = await OfflineStore.instance.readHttpResponse(
                  key: _offlineCacheKey(request),
                  userScope: token.hashCode.toString(),
                );
                if (cached != null) {
                  handler.resolve(Response<dynamic>(
                    requestOptions: request,
                    data: cached,
                    statusCode: 200,
                    statusMessage: 'Offline cache',
                    headers: Headers.fromMap({
                      'x-karnama-offline-cache': ['1'],
                    }),
                  ));
                  return;
                }
              }
            } catch (_) {
              // Fall through to original network error.
            }
          }
          handler.next(error);
        },
      ),
    );

  static String _offlineCacheKey(RequestOptions request) {
    final query = Map<String, dynamic>.from(request.queryParameters);
    final sortedKeys = query.keys.toList()..sort();
    final normalizedQuery = <String, dynamic>{
      for (final key in sortedKeys) key: query[key],
    };
    return '${request.method.toUpperCase()}:${request.uri.path}?${jsonEncode(normalizedQuery)}';
  }

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
