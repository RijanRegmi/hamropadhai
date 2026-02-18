// class ApiEndpoints {
//   ApiEndpoints._();

//   // static const String deviceIp = "192.168.1.5";
//   static const String deviceIp = "192.168.1.9";

//   static const String baseUrl = "http://$deviceIp:5050/api/auth";

//   // static const String baseUrl = "http://10.0.2.2:5050/api/auth";

//   //image

//   static const String imageBaseUrl = "http://$deviceIp:5050";

//   // static const String imageBaseUrl = "http://10.0.2.2:5050";

//   static const Duration connectionTimeout = Duration(seconds: 10);
//   static const Duration receiveTimeout = Duration(seconds: 10);

//   static const String signup = "/register";
//   static const String login = "/login";
//   static const String profile = "/profile";
//   static const String updateProfile = "/profile";
//   static const String uploadProfileImage = "/upload-profile-image";
// }

import 'dart:io';

class ApiEndpoints {
  ApiEndpoints._();

  static const String _emulatorHost = '10.0.2.2';
  static const String _physicalDeviceHost = '192.168.1.6';

  static String get _host =>
      Platform.isAndroid ? _emulatorHost : _physicalDeviceHost;

  static const bool usePhysicalDevice = false;

  static String get _resolvedHost =>
      usePhysicalDevice ? _physicalDeviceHost : _emulatorHost;

  static String get baseUrl => 'http://$_resolvedHost:5050/api/auth';
  static String get imageBaseUrl => 'http://$_resolvedHost:5050';

  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  static const String signup = '/register';
  static const String login = '/login';
  static const String profile = '/profile';
  static const String updateProfile = '/profile';
  static const String uploadProfileImage = '/upload-profile-image';
}
