// class ApiEndpoints {
//   ApiEndpoints._();

//   static const String _emulatorHost = '10.0.2.2';
//   static const String _physicalDeviceHost = '192.168.1.5';

//   // static const bool usePhysicalDevice = false;
//   static const bool usePhysicalDevice = true;

//   static String get _resolvedHost =>
//       usePhysicalDevice ? _physicalDeviceHost : _emulatorHost;

//   static String get baseUrl => 'http://$_resolvedHost:5050/api/auth';
//   static String get imageBaseUrl => 'http://$_resolvedHost:5050';

//   static const Duration connectionTimeout = Duration(seconds: 10);
//   static const Duration receiveTimeout = Duration(seconds: 10);

//   static const String signup = '/register';
//   static const String login = '/login';
//   static const String profile = '/profile';
//   static const String updateProfile = '/profile';
//   static const String uploadProfileImage = '/upload-profile-image';
// }

//==========================

// import 'package:shared_preferences/shared_preferences.dart';

// class ApiEndpoints {
//   ApiEndpoints._();

//   static const String _emulatorHost = '10.0.2.2';
//   static const String _defaultPhysicalDeviceHost = '192.168.1.9';
//   static const String _hostKey = 'server_host';

//   static const bool usePhysicalDevice = false;

//   static String? _cachedHost;

//   static Future<void> init() async {
//     final prefs = await SharedPreferences.getInstance();
//     if (prefs.getString(_hostKey) == null) {
//       await prefs.setString(_hostKey, _defaultPhysicalDeviceHost);
//     }
//     _cachedHost = prefs.getString(_hostKey) ?? _defaultPhysicalDeviceHost;
//   }

//   static Future<void> setServerHost(String host) async {
//     final trimmed = host.trim();
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_hostKey, trimmed);
//     _cachedHost = trimmed;
//   }

//   static Future<String> getServerHost() async {
//     if (_cachedHost != null) return _cachedHost!;
//     final prefs = await SharedPreferences.getInstance();
//     final host = prefs.getString(_hostKey) ?? _defaultPhysicalDeviceHost;
//     _cachedHost = host;
//     return host;
//   }

//   static Future<String> get _resolvedHost async =>
//       usePhysicalDevice ? await getServerHost() : _emulatorHost;

//   static Future<String> get baseUrl async =>
//       'http://${await _resolvedHost}:5050/api/auth';

//   static Future<String> get imageBaseUrl async =>
//       'http://${await _resolvedHost}:5050';

//   static const Duration connectionTimeout = Duration(seconds: 10);
//   static const Duration receiveTimeout = Duration(seconds: 10);

//   static const String signup = '/register';
//   static const String login = '/login';
//   static const String profile = '/profile';
//   static const String updateProfile = '/profile';
//   static const String uploadProfileImage = '/upload-profile-image';
// }

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class ApiEndpoints {
  ApiEndpoints._();

  static const String _emulatorHost = '10.0.2.2';
  static const String _defaultPhysicalDeviceHost = '192.168.1.9';
  static const String _hostKey = 'server_host';
  static const String _isEmulatorKey = 'is_emulator';

  static String? _cachedHost;
  static bool _isEmulator = false;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final hostname = Platform.localHostname.toLowerCase();
      _isEmulator =
          hostname.contains('emulator') ||
          hostname.contains('generic') ||
          hostname.contains('sdk') ||
          hostname.contains('gphone');
    } catch (_) {
      _isEmulator = false;
    }

    if (_isEmulator) {
      _cachedHost = _emulatorHost;
    } else {
      await prefs.setString(_hostKey, _defaultPhysicalDeviceHost);
      _cachedHost = _defaultPhysicalDeviceHost;
    }
  }

  static Future<void> setServerHost(String host) async {
    final trimmed = host.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hostKey, trimmed);
    _cachedHost = trimmed;
  }

  static Future<String> getServerHost() async {
    if (_cachedHost != null) return _cachedHost!;
    if (_isEmulator) return _emulatorHost;
    final prefs = await SharedPreferences.getInstance();
    final host = prefs.getString(_hostKey) ?? _defaultPhysicalDeviceHost;
    _cachedHost = host;
    return host;
  }

  static Future<String> get _resolvedHost async => await getServerHost();

  static Future<String> get baseUrl async =>
      'http://${await _resolvedHost}:5050/api/auth';

  static Future<String> get imageBaseUrl async =>
      'http://${await _resolvedHost}:5050';

  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  static const String signup = '/register';
  static const String login = '/login';
  static const String profile = '/profile';
  static const String updateProfile = '/profile';
  static const String uploadProfileImage = '/upload-profile-image';
}
