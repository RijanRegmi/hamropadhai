class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = "http://10.0.2.2:5050/api/auth";

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String signup = "/register";
  static const String login = "/login";
}
