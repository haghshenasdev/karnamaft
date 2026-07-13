import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  AuthStorage._();

  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  static const _tokenKey = "access_token";

  //--------------------------------------------------
  // Save Token
  //--------------------------------------------------

  static Future<void> saveToken(
    String token,
  ) async {
    await _storage.write(
      key: _tokenKey,
      value: token,
    );
  }

  //--------------------------------------------------
  // Read Token
  //--------------------------------------------------

  static Future<String?> getToken() async {
    return _storage.read(
      key: _tokenKey,
    );
  }

  //--------------------------------------------------
  // Is Login
  //--------------------------------------------------

  static Future<bool> isLoggedIn() async {
    final token = await getToken();

    return token != null && token.isNotEmpty;
  }

  //--------------------------------------------------
  // Logout
  //--------------------------------------------------

  static Future<void> logout() async {
    await _storage.delete(
      key: _tokenKey,
    );
  }
}