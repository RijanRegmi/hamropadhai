import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hamropadhai/features/auth/data/datasources/local/auth_local_datasource.dart';
import 'package:hamropadhai/features/onboarding/presentation/pages/onboarding_screen1.dart';
import 'package:hamropadhai/features/dashboard/presentation/pages/bottom_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Remove native splash and go straight to destination
    FlutterNativeSplash.remove();

    Widget destination;
    try {
      final authLocalDatasource = AuthLocalDatasource();
      final isLoggedIn = await authLocalDatasource.isLoggedIn();
      destination = isLoggedIn
          ? const BottomNavigationScreen()
          : const OnboardingScreen1();
    } catch (e) {
      debugPrint('Error checking login status: $e');
      destination = const OnboardingScreen1();
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionDuration: Duration.zero, // instant, no animation
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Invisible screen - user never sees this, goes straight to destination
    return const Scaffold(backgroundColor: Color(0xFFFFF8F0));
  }
}
