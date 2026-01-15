import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'signup_screen.dart';
import '../../../dashboard/presentation/pages/bottom_navigation_screen.dart';
import '../view_model/auth_viewmodel.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool hidePassword = true;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authViewModelProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Image.asset("assets/images/books.png", height: 120),
            const SizedBox(height: 10),
            const Text(
              "LOGIN",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            TextField(
              controller: emailController,
              decoration: _dec(Icons.email_outlined, "Email or Phone Number"),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: passwordController,
              obscureText: hidePassword,
              decoration: _passwordDec(),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                onPressed: loading
                    ? null
                    : () async {
                        try {
                          await ref
                              .read(authViewModelProvider.notifier)
                              .login(
                                email: emailController.text.trim(),
                                password: passwordController.text,
                              );

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BottomNavigationScreen(),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      },
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Log in",
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),

            const SizedBox(height: 20),
            const Text("Don't have account?"),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                );
              },
              child: const Text("Create account"),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(IconData icon, String label) {
    return InputDecoration(
      prefixIcon: Icon(icon),
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  InputDecoration _passwordDec() {
    return InputDecoration(
      prefixIcon: const Icon(Icons.lock_outline),
      labelText: "Password",
      suffixIcon: IconButton(
        icon: Icon(hidePassword ? Icons.visibility_off : Icons.visibility),
        onPressed: () => setState(() => hidePassword = !hidePassword),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
