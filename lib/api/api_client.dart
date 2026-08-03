import 'package:dio/dio.dart';

import '../storage/auth_storage.dart';

class ApiClient {
  ApiClient._();

  static final Dio dio =
      Dio(
          BaseOptions(
            baseUrl: "https://hajideligani.ir/api",

            connectTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(minutes: 2),
            receiveTimeout: const Duration(minutes: 2),

            headers: {
              "Accept": "application/json",
              "Content-Type": "application/json",
            },
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              final token = await AuthStorage.getToken();

              if (token != null && token.isNotEmpty) {
                options.headers["Authorization"] = "Bearer $token";
              }

              handler.next(options);
            },
          ),
        );
}
