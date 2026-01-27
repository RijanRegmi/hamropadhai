import 'package:flutter/material.dart';
import 'package:hamropadhai/theme/theme_data.dart';
import 'package:hamropadhai/features/splash/presentation/pages/splash_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HamroPadhai',
      theme: getApplicationTheme(),
      home: const SplashScreen(),
    );
  }
}
