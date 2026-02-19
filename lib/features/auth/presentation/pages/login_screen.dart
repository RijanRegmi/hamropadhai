import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'signup_screen.dart';
import 'package:hamropadhai/features/auth/presentation/pages/forgot_password_screen.dart';
import '../../../dashboard/presentation/pages/bottom_navigation_screen.dart';
import '../view_model/auth_viewmodel.dart';
import '../widgets/auth_header.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_password_field.dart';
import '../widgets/custom_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (usernameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter username');
      return;
    }

    if (passwordController.text.isEmpty) {
      _showErrorSnackBar('Please enter password');
      return;
    }

    try {
      await ref
          .read(authViewModelProvider.notifier)
          .login(
            username: usernameController.text.trim(),
            password: passwordController.text,
          );

      if (mounted) {
        // Invalidate all cached providers so new account data loads fresh
        ref.invalidate(profileProvider);

        _showSuccessSnackBar('Login successful!');

        // Use username as key so BottomNavigationScreen fully rebuilds
        // when switching accounts
        final username = usernameController.text.trim();

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => BottomNavigationScreen(key: ValueKey(username)),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      String errorMessage = e.toString();

      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      if (errorMessage.contains('timeout') ||
          errorMessage.contains('Timeout')) {
        _showErrorSnackBar(
          'Connection timeout! Please check:\n'
          '• Is your server running?\n'
          '• Is your network working?\n'
          '• Try again',
        );
      } else if (errorMessage.contains('SocketException') ||
          errorMessage.contains('Cannot connect')) {
        _showErrorSnackBar(
          '🔌 Cannot connect to server!\n'
          '• Make sure backend is running\n'
          '• Check server URL in ApiEndpoints',
        );
      } else if (errorMessage.contains('Invalid credentials')) {
        _showErrorSnackBar('Invalid username or password');
      } else if (errorMessage.contains('Token not found')) {
        _showErrorSnackBar('Server response error\nPlease contact support');
      } else {
        _showErrorSnackBar('Login failed: $errorMessage');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authViewModelProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const AuthHeader(title: "LOGIN"),

              CustomTextField(
                controller: usernameController,
                labelText: "Username",
                prefixIcon: Icons.account_circle_outlined,
              ),
              const SizedBox(height: 15),

              CustomPasswordField(
                controller: passwordController,
                labelText: "Password",
              ),

              // ✅ Forgot Password — right aligned, sits between password and login button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Color(0xFF7C3AED),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              CustomButton(
                text: "Log in",
                isLoading: loading,
                onPressed: _handleLogin,
              ),

              const SizedBox(height: 20),
              const Text("Don't have an account?"),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  );
                },
                child: const Text(
                  "Create account",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
