// class ApiEndpoints {
//   ApiEndpoints._();

//   // static const String deviceIp = "192.168.1.5";
//   static const String deviceIp = "192.168.1.5";

//   // static const String baseUrl = "http://$deviceIp:5050/api/auth";

//   static const String baseUrl = "http://10.0.2.2:5050/api/auth";

//   //image

//   // static const String imageBaseUrl = "http://$deviceIp:5050";

//   static const String imageBaseUrl = "http://10.0.2.2:5050";

//   static const Duration connectionTimeout = Duration(seconds: 10);
//   static const Duration receiveTimeout = Duration(seconds: 10);

//   static const String signup = "/register";
//   static const String login = "/login";
//   static const String profile = "/profile";
//   static const String uploadProfileImage = "/upload-profile-image";
// }
class ApiEndpoints {
  ApiEndpoints._();

  static const String deviceIp = "192.168.1.5";
  static const String baseUrl = "http://10.0.2.2:5050/api/auth";
  static const String imageBaseUrl = "http://10.0.2.2:5050";

  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  static const String signup = "/register";
  static const String login = "/login";
  static const String profile = "/profile";
  static const String updateProfile = "/profile";
  static const String uploadProfileImage = "/upload-profile-image";
}
