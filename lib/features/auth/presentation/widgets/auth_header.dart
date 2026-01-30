import 'package:flutter/material.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final double logoHeight;

  const AuthHeader({super.key, required this.title, this.logoHeight = 120});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 0),
        Image.asset("assets/images/books.png", height: logoHeight),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
