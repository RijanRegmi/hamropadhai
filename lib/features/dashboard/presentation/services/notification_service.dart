import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _base = 'http://10.0.2.2:5050';
  static const _seenKey = 'hp_seen_notif_ids';
  static const _chAssign = 'hp_assignments';
  static const _chRoutine = 'hp_routines';
  static const _chNotice = 'hp_notices';

  final _plugin = FlutterLocalNotificationsPlugin();
  Timer? _timer;
  String? _token;

  Future<void> init() async {
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

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await android?.createNotificationChannel(
      AndroidNotificationChannel(
        _chAssign,
        'Assignments',
        description: 'Assignment alerts',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );

    await android?.createNotificationChannel(
      AndroidNotificationChannel(
        _chRoutine,
        'Routine',
        description: 'Routine alerts',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    await android?.createNotificationChannel(
      AndroidNotificationChannel(
        _chNotice,
        'Notices',
        description: 'School notice alerts',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );

    await android?.requestNotificationsPermission();
  }

  void startPolling(String token) {
    _token = token;
    _timer?.cancel();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _poll());
  }

  Future<void> stopPolling() async {
    _timer?.cancel();
    _timer = null;
    _token = null;
    (await SharedPreferences.getInstance()).remove(_seenKey);
  }

  Future<void> _poll() async {
    final token = _token;
    if (token == null) return;
    try {
      final res = await http
          .get(
            Uri.parse('$_base/api/student/notifications'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return;

      final items = List<Map<String, dynamic>>.from(
        (jsonDecode(res.body) as Map)['data'] ?? [],
      );

      final prefs = await SharedPreferences.getInstance();
      final seen = Set<String>.from(prefs.getStringList(_seenKey) ?? []);
      final newIds = <String>[];

      for (final n in items) {
        final id = n['_id'] as String? ?? '';
        if (id.isEmpty || seen.contains(id)) continue;
        await _show(n);
        newIds.add(id);
      }

      if (newIds.isNotEmpty) {
        seen.addAll(newIds);
        final list = seen.toList();
        if (list.length > 300) list.removeRange(0, list.length - 300);
        await prefs.setStringList(_seenKey, list);
      }
    } catch (_) {}
  }

  Future<void> _show(Map<String, dynamic> n) async {
    final title = n['title'] as String? ?? 'HamroPadhai';
    final message = n['message'] as String? ?? '';
    final type = n['type'] as String? ?? '';
    final nId = n['_id'] as String? ?? '';
    final intId = (nId.hashCode.abs() % 2000000000) + 1;

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

    await _plugin.show(
      intId,
      title,
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          chId,
          chName,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          styleInformation: BigTextStyleInformation(message),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
      ),
      payload: jsonEncode({'id': nId, 'type': type}),
    );
  }

  void _onTap(NotificationResponse r) =>
      navigatorKey.currentState?.pushNamed('/notifications');
}

@pragma('vm:entry-point')
void _onTapBg(NotificationResponse r) {}
