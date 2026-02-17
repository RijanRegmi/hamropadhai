import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ✅ GLOBAL: Required for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // ✅ Read from data map — backend sends data-only (no notification field)
  await NotificationService.instance._showFromData(message.data);
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _base = 'http://10.0.2.2:5050';
  static const _seenKey = 'hp_seen_notif_ids';
  static const _fcmTokenKey = 'hp_fcm_token';
  static const _chAssign = 'hp_assignments';
  static const _chRoutine = 'hp_routines';
  static const _chNotice = 'hp_notices';

  final _plugin = FlutterLocalNotificationsPlugin();
  final _messaging = FirebaseMessaging.instance;
  String? _token;
  bool _isInitialized = false;

  // ══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp();
      print('✅ Firebase initialized');

      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          ),
        ),
        onDidReceiveNotificationResponse: _onTap,
        onDidReceiveBackgroundNotificationResponse: _onTapBg,
      );

      await _createChannels();
      await _requestPermissions();
      await _configureFCM();

      _isInitialized = true;
      print('✅ NotificationService fully initialized');
    } catch (e) {
      print('❌ NotificationService init error: $e');
    }
  }

  Future<void> _createChannels() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    await android.createNotificationChannel(
      AndroidNotificationChannel(
        _chAssign,
        'Assignments',
        description: 'Assignment alerts',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        _chRoutine,
        'Routine',
        description: 'Routine alerts',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        _chNotice,
        'Notices',
        description: 'School notice alerts',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  Future<void> _requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    print('📱 FCM Permission status: ${settings.authorizationStatus}');
  }

  Future<void> _configureFCM() async {
    // ✅ Background/terminated handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // ✅ Foreground handler — read from data map
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Foreground message received');
      _showFromData(message.data);
    });

    // ✅ Tap handler when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 Notification tapped');
      navigatorKey.currentState?.pushNamed('/notifications');
    });

    // ✅ App opened from terminated state via notification tap
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      Future.delayed(const Duration(seconds: 1), () {
        navigatorKey.currentState?.pushNamed('/notifications');
      });
    }

    _messaging.onTokenRefresh.listen(_onTokenRefresh);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHOW NOTIFICATION — reads title/body from data map (data-only FCM)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _showFromData(Map<String, dynamic> data) async {
    // ✅ Backend puts title and body inside the data map
    final title = data['title'] as String? ?? 'HamroPadhai';
    final body = data['body'] as String? ?? '';
    final type = data['type'] as String? ?? '';

    // Deduplicate using title+body hash so same message never shows twice
    final dedupeKey = '${title}_$body'.hashCode.toString();
    final prefs = await SharedPreferences.getInstance();
    final seen = Set<String>.from(prefs.getStringList(_seenKey) ?? []);
    if (seen.contains(dedupeKey)) return;

    final chId = type.contains('assignment')
        ? _chAssign
        : type.contains('routine')
        ? _chRoutine
        : _chNotice;
    final chName = chId == _chAssign
        ? 'Assignments'
        : chId == _chRoutine
        ? 'Routine'
        : 'Notices';

    final intId = dedupeKey.hashCode.abs() % 2000000000;

    await _plugin.show(
      intId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          chId,
          chName,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
      ),
      payload: jsonEncode(data),
    );

    // Mark as seen so it never duplicates
    seen.add(dedupeKey);
    final list = seen.toList();
    if (list.length > 300) list.removeRange(0, list.length - 300);
    await prefs.setStringList(_seenKey, list);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FCM TOKEN MANAGEMENT
  // ══════════════════════════════════════════════════════════════════════════

  Future<String?> getFCMToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenLocally(token);
        print('📱 FCM Token: ${token.substring(0, 20)}...');
      }
      return token;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> _onTokenRefresh(String newToken) async {
    print('🔄 FCM Token refreshed');
    await _saveTokenLocally(newToken);
    if (_token != null) await _sendTokenToBackend(newToken, _token!);
  }

  Future<void> _saveTokenLocally(String fcmToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenKey, fcmToken);
  }

  Future<String?> _getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fcmTokenKey);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // START / STOP
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> startService(String authToken) async {
    _token = authToken;
    final fcmToken = await getFCMToken();
    if (fcmToken != null) {
      await _sendTokenToBackend(fcmToken, authToken);
    } else {
      print('⚠️ Could not get FCM token');
    }
  }

  Future<void> _sendTokenToBackend(String fcmToken, String authToken) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_base/api/student/fcm-token'),
            headers: {
              'Authorization': 'Bearer $authToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'fcmToken': fcmToken}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ FCM token sent to backend');
      } else {
        print('! Failed to send FCM token: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error sending FCM token: $e');
    }
  }

  Future<void> stopService() async {
    try {
      final fcmToken = await _getStoredToken();
      if (fcmToken != null && _token != null) {
        await http
            .delete(
              Uri.parse('$_base/api/student/fcm-token'),
              headers: {
                'Authorization': 'Bearer $_token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({'fcmToken': fcmToken}),
            )
            .timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      print('❌ Error removing FCM token: $e');
    }

    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seenKey);
    await prefs.remove(_fcmTokenKey);
    await _messaging.deleteToken();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAP HANDLERS
  // ══════════════════════════════════════════════════════════════════════════

  void _onTap(NotificationResponse r) {
    navigatorKey.currentState?.pushNamed('/notifications');
  }
}

@pragma('vm:entry-point')
void _onTapBg(NotificationResponse r) {}
