import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'login_screen.dart';
import '../view_model/auth_viewmodel.dart';
import '../widgets/auth_header.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_password_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/gender_selector.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  String gender = 'male';

  String? usernameError;
  String? emailError;
  String? phoneError;

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  void _clearFieldError(String field) {
    setState(() {
      switch (field) {
        case 'username':
          usernameError = null;
          break;
        case 'email':
          emailError = null;
          break;
        case 'phone':
          phoneError = null;
          break;
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleSignup() async {
    setState(() {
      usernameError = null;
      emailError = null;
      phoneError = null;
    });

    // Validate all fields
    if (nameController.text.trim().isEmpty) {
      _showSnackBar("Please enter your full name", isError: true);
      return;
    }

    if (usernameController.text.trim().isEmpty) {
      _showSnackBar("Please enter a username", isError: true);
      return;
    }

    if (emailController.text.trim().isEmpty) {
      _showSnackBar("Please enter your email", isError: true);
      return;
    }

    if (phoneController.text.trim().isEmpty) {
      _showSnackBar("Please enter your phone number", isError: true);
      return;
    }

    if (passwordController.text.isEmpty) {
      _showSnackBar("Please enter a password", isError: true);
      return;
    }

    if (passwordController.text.length < 6) {
      _showSnackBar("Password must be at least 6 characters", isError: true);
      return;
    }

    // Validate passwords match
    if (passwordController.text != confirmController.text) {
      _showSnackBar("Passwords do not match", isError: true);
      return;
    }

    try {
      await ref
          .read(authViewModelProvider.notifier)
          .signup(
            fullName: nameController.text.trim(),
            username: usernameController.text.trim(),
            email: emailController.text.trim(),
            phone: phoneController.text.trim(),
            password: passwordController.text,
            gender: gender,
          );

      _showSnackBar("Signup successful!");

      // Navigate to login after a short delay
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      String errorMessage = e.toString();

      // Clean up error message
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      // Handle timeout errors
      if (errorMessage.contains('timeout') ||
          errorMessage.contains('Timeout')) {
        _showSnackBar(
          'Connection timeout! Please check:\n'
          '• Is your server running?\n'
          '• Is your network working?\n'
          '• Try again',
          isError: true,
        );
        return;
      }

      // Handle connection errors
      if (errorMessage.contains('SocketException') ||
          errorMessage.contains('Cannot connect')) {
        _showSnackBar(
          'Cannot connect to server!\n'
          '• Make sure backend is running\n'
          '• Check server URL in ApiEndpoints',
          isError: true,
        );
        return;
      }

      if (errorMessage.contains("Username already exists") ||
          errorMessage.contains("username")) {
        setState(() {
          usernameError = "Username already exists";
        });
        _showSnackBar("Username already taken", isError: true);
      } else if (errorMessage.contains("Email already exists") ||
          errorMessage.contains("email")) {
        setState(() {
          emailError = "Email already exists";
        });
        _showSnackBar("Email already registered", isError: true);
      } else if (errorMessage.contains("Phone number already exists") ||
          errorMessage.contains("phone")) {
        setState(() {
          phoneError = "Phone number already exists";
        });
        _showSnackBar("Phone number already registered", isError: true);
      } else {
        _showSnackBar("Signup failed: $errorMessage", isError: true);
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
              const AuthHeader(title: "SIGNUP"),

              CustomTextField(
                controller: nameController,
                labelText: "Full Name",
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 15),

              CustomTextField(
                controller: usernameController,
                labelText: "Username",
                prefixIcon: Icons.account_circle_outlined,
                errorText: usernameError,
                onChanged: (_) => _clearFieldError('username'),
              ),
              const SizedBox(height: 15),

              CustomTextField(
                controller: emailController,
                labelText: "Email",
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                errorText: emailError,
                onChanged: (_) => _clearFieldError('email'),
              ),
              const SizedBox(height: 15),

              CustomTextField(
                controller: phoneController,
                labelText: "Phone Number",
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                hintText: "98XXXXXXXX",
                errorText: phoneError,
                onChanged: (_) => _clearFieldError('phone'),
              ),
              const SizedBox(height: 15),

              CustomPasswordField(
                controller: passwordController,
                labelText: "Password",
              ),
              const SizedBox(height: 15),

              CustomPasswordField(
                controller: confirmController,
                labelText: "Confirm Password",
              ),
              const SizedBox(height: 15),

              GenderSelector(
                selectedGender: gender,
                onGenderChanged: (value) {
                  setState(() {
                    gender = value;
                  });
                },
              ),
              const SizedBox(height: 20),

              CustomButton(
                text: "Sign up",
                isLoading: loading,
                onPressed: _handleSignup,
              ),

              const SizedBox(height: 20),
              const Text("Already have an account?"),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text(
                  "LOGIN",
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
