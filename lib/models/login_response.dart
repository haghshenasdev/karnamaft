class LoginResponse {
  final bool success;

  final String message;

  final String token;

  const LoginResponse({
    required this.success,
    required this.message,
    required this.token,
  });

  factory LoginResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return LoginResponse(
      success: json["success"] ?? false,
      message: json["message"] ?? "",
      token: json["token"] ?? "",
    );
  }
}