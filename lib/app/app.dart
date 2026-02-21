import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hamropadhai/features/splash/presentation/pages/splash_screen.dart';
import 'package:hamropadhai/features/dashboard/presentation/pages/notification_screen.dart';
import 'package:hamropadhai/features/dashboard/presentation/services/notification_service.dart';
import 'package:hamropadhai/core/theme/theme_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(resolvedThemeModeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HamroPadhai',
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: themeMode,
      navigatorKey: navigatorKey,
      routes: {'/notifications': (_) => const NotificationScreen()},
      home: const SplashScreen(),
    );
  }
}
