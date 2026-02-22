import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'signup_screen.dart';
import 'package:hamropadhai/features/auth/presentation/pages/forgot_password_screen.dart';
import '../../../dashboard/presentation/pages/bottom_navigation_screen.dart';
import '../view_model/auth_viewmodel.dart';
import '../widgets/auth_header.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_password_field.dart';
import '../widgets/custom_button.dart';
import 'package:hamropadhai/core/providers/biometric_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();

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

      if (!mounted) return;
      ref.invalidate(profileProvider);
      _showSuccessSnackBar('Login successful!');

      final username = usernameController.text.trim();
      final password = passwordController.text;

      final biometricEnabled = ref.read(biometricEnabledProvider);
      final savedAccounts = ref.read(biometricAccountsProvider);
      final alreadySaved = savedAccounts.any((a) => a['username'] == username);

      // ✅ Ask to save fingerprint if:
      //    - biometric is enabled AND this account isn't saved yet
      //    OR
      //    - biometric is enabled AND account WAS saved but credentials are missing
      //      (e.g. user turned off, turned back on, logged in again)
      bool shouldAsk = biometricEnabled && !alreadySaved;

      // Also check if enabled + saved but credentials got wiped somehow
      if (biometricEnabled && alreadySaved) {
        final existingPassword = await BiometricCredentialStorage.getPassword(
          username,
        );
        if (existingPassword == null || existingPassword.isEmpty) {
          // Credentials missing — remove stale account entry and ask again
          await ref
              .read(biometricAccountsProvider.notifier)
              .removeAccount(username);
          shouldAsk = true;
        }
      }

      if (shouldAsk) {
        await _promptSaveBiometric(username, password);
      }

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => BottomNavigationScreen(key: ValueKey(username)),
        ),
        (route) => false,
      );
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: '))
        errorMessage = errorMessage.substring(11);
      if (errorMessage.contains('timeout') ||
          errorMessage.contains('Timeout')) {
        _showErrorSnackBar(
          'Connection timeout! Please check:\n• Is your server running?\n• Is your network working?',
        );
      } else if (errorMessage.contains('SocketException') ||
          errorMessage.contains('Cannot connect')) {
        _showErrorSnackBar(
          '🔌 Cannot connect to server!\n• Make sure backend is running',
        );
      } else if (errorMessage.contains('Invalid credentials')) {
        _showErrorSnackBar('Invalid username or password');
      } else if (errorMessage.contains('Token not found')) {
        _showErrorSnackBar('Server response error. Please contact support');
      } else {
        _showErrorSnackBar('Login failed: $errorMessage');
      }
    }
  }

  Future<void> _promptSaveBiometric(String username, String password) async {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A1A);

    final bool? wantsToEnable = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.fingerprint, color: Color(0xFF7C3AED), size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Enable Fingerprint Login?',
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Would you like to use fingerprint to log in as "@$username" next time?',
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Not Now',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.fingerprint, size: 18),
            label: const Text('Yes, Enable'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (wantsToEnable != true) return;
    if (!mounted) return;

    try {
      final verified = await _localAuth.authenticate(
        localizedReason: 'Scan fingerprint to save for "@$username"',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (verified && mounted) {
        await ref
            .read(biometricAccountsProvider.notifier)
            .addAccount(username, username);
        await BiometricCredentialStorage.saveCredentials(username, password);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Fingerprint saved! Use it to login next time.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Fingerprint not verified. You can try again next login.',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fingerprint error: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    final savedAccounts = ref.read(biometricAccountsProvider);

    if (savedAccounts.isEmpty) {
      await _showInfoDialog(
        title: 'No Accounts Saved',
        message:
            'To use fingerprint login, first log in once with your username and password.\n\nYou\'ll then be asked if you want to enable fingerprint for that account.',
      );
      return;
    }

    String? selectedUsername;
    if (savedAccounts.length == 1) {
      selectedUsername = savedAccounts.first['username'];
    } else {
      selectedUsername = await _showAccountPickerDialog(savedAccounts);
      if (selectedUsername == null) return;
    }

    try {
      final bool canCheck = await _localAuth.canCheckBiometrics;
      final bool isSupported = await _localAuth.isDeviceSupported();
      if (!canCheck || !isSupported) {
        _showErrorSnackBar(
          'Biometric authentication is not available on this device',
        );
        return;
      }

      final bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan fingerprint to log in as "$selectedUsername"',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!authenticated || !mounted) return;

      final password = await BiometricCredentialStorage.getPassword(
        selectedUsername!,
      );

      if (password == null || password.isEmpty) {
        _showErrorSnackBar(
          'Saved credentials not found. Please log in with password once to re-link fingerprint.',
        );
        await ref
            .read(biometricAccountsProvider.notifier)
            .removeAccount(selectedUsername);
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 12),
                Text('Logging in...'),
              ],
            ),
            duration: Duration(seconds: 10),
            backgroundColor: Color(0xFF7C3AED),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      await ref
          .read(authViewModelProvider.notifier)
          .login(username: selectedUsername, password: password);

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ref.invalidate(profileProvider);
      _showSuccessSnackBar('Welcome back, $selectedUsername!');

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              BottomNavigationScreen(key: ValueKey(selectedUsername)),
        ),
        (route) => false,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showErrorSnackBar(
        'Login failed: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  Future<void> _showInfoDialog({
    required String title,
    required String message,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A1A);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.fingerprint, color: Color(0xFF7C3AED), size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF7C3AED),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showAccountPickerDialog(
    List<Map<String, String>> accounts,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.fingerprint,
                      color: Color(0xFF7C3AED),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Choose Account',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Which account do you want to log into?',
                style: TextStyle(fontSize: 13, color: textSecondary),
              ),
              const SizedBox(height: 16),
              ...accounts.map((account) {
                final username = account['username'] ?? '';
                final displayName = account['displayName'] ?? username;
                return GestureDetector(
                  onTap: () => Navigator.pop(ctx, username),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF7C3AED).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(
                            0xFF7C3AED,
                          ).withOpacity(0.15),
                          child: Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Color(0xFF7C3AED),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                '@$username',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.fingerprint,
                          color: Color(0xFF7C3AED),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: textSecondary, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authViewModelProvider);
    final biometricEnabled = ref.watch(biometricEnabledProvider);

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

              if (biometricEnabled) ...[
                const SizedBox(height: 16),
                Row(
                  children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _handleBiometricLogin,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF7C3AED),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFF7C3AED).withOpacity(0.05),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fingerprint,
                          color: Color(0xFF7C3AED),
                          size: 28,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Login with Fingerprint',
                          style: TextStyle(
                            color: Color(0xFF7C3AED),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),
              const Text("Don't have an account?"),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                ),
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
