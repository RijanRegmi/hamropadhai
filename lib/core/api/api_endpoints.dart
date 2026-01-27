class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = "http://192.168.1.5:5050/api/auth";

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String signup = "/register";
  static const String login = "/login";
  static const String profile = "/profile";
  static const String uploadProfileImage = "/upload-profile-image";
}
