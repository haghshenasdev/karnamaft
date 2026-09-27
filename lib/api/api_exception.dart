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
  bool get isServerError => statusCode != null && statusCode! >= 500;

  @override
  String toString() => message;
}
