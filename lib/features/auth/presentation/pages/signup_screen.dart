import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'login_screen.dart';
import '../view_model/auth_viewmodel.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  bool hidePassword = true;
  bool hideConfirm = true;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  String gender = 'male';

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
              "SIGNUP",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            TextField(
              controller: nameController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_outline),
                labelText: "Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: emailController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.email_outlined),
                labelText: "Email",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.phone),
                labelText: "Phone Number",
                hintText: "98XXXXXXXX",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: passwordController,
              obscureText: hidePassword,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    hidePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => hidePassword = !hidePassword),
                ),
                labelText: "Password",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: confirmController,
              obscureText: hideConfirm,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    hideConfirm ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => hideConfirm = !hideConfirm),
                ),
                labelText: "Confirm Password",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("Male"),
                    value: "male",
                    groupValue: gender,
                    onChanged: (value) {
                      setState(() => gender = value!);
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("Female"),
                    value: "female",
                    groupValue: gender,
                    onChanged: (value) {
                      setState(() => gender = value!);
                    },
                  ),
                ),
              ],
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
                        if (passwordController.text != confirmController.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Passwords do not match"),
                            ),
                          );
                          return;
                        }

                        try {
                          await ref
                              .read(authViewModelProvider.notifier)
                              .signup(
                                fullName: nameController.text.trim(),
                                email: emailController.text.trim(),
                                phone: phoneController.text.trim(),
                                password: passwordController.text,
                                gender: gender,
                              );

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Signup successful")),
                          );

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
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
                        "Sign up",
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),

            const SizedBox(height: 20),
            const Text("Already have account?"),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text("LOGIN"),
            ),
          ],
        ),
      ),
    );
  }
}
