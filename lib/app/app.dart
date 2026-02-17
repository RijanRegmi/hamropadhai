import 'package:flutter/material.dart';
import 'package:hamropadhai/theme/theme_data.dart';
import 'package:hamropadhai/features/splash/presentation/pages/splash_screen.dart';
import 'package:hamropadhai/features/dashboard/presentation/pages/notification_screen.dart';
// ✅ Import navigatorKey from FCM service ONLY — not the old notification_service.dart
import 'package:hamropadhai/features/dashboard/presentation/services/fcm_notification_service.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HamroPadhai',
      theme: getApplicationTheme(),
      navigatorKey: navigatorKey, // ✅ from fcm_notification_service.dart
      routes: {'/notifications': (_) => const NotificationScreen()},
      home: const SplashScreen(),
    );
  }
}
