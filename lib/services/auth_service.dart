import 'package:karnamaft/api/api_error_handler.dart';
import 'package:karnamaft/models/user_model.dart';
import '../api/api_client.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

class AuthService {
  const AuthService();

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await ApiClient.dio.post("/auth/login", data: {
        ...request.toJson(),
        "device_name": "karnama-mobile",
      });
      return LoginResponse.fromJson(response.data);
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<UserModel> me() async {
    try {
      final response = await ApiClient.dio.get("/me");
      return UserModel.fromJson(response.data["data"]);
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<void> logout() async {
    try {
      await ApiClient.dio.post("/logout");
    } finally {
      // Token removal is handled by the caller/storage.
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String password,
  }) async {
    try {
      await ApiClient.dio.post("/password", data: {
        "current_password": currentPassword,
        "password": password,
        "password_confirmation": password,
      });
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }
}
