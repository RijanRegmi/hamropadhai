import 'package:flutter/material.dart';
import 'dart:async';
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
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for 2 seconds to show splash screen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      // Check if user is logged in
      final authLocalDatasource = AuthLocalDatasource();
      final isLoggedIn = await authLocalDatasource.isLoggedIn();

      if (!mounted) return;

      if (isLoggedIn) {
        // User is logged in, go to home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const BottomNavigationScreen(),
          ),
        );
      } else {
        // User is not logged in, go to onboarding
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen1()),
        );
      }
    } catch (e) {
      print('Error checking login status: $e');

      if (!mounted) return;

      // If there's an error, go to onboarding to be safe
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen1()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/images/logo.png", width: 150),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
