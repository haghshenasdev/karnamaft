import 'package:karnamaft/api/api_error_handler.dart';
import 'package:karnamaft/models/user_model.dart';

import '../api/api_client.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

class AuthService {
  const AuthService();

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await ApiClient.dio.post(
        "/auth/login",
        data: request.toJson(),
      );

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
}
