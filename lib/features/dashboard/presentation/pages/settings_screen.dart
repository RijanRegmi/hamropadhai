import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:hamropadhai/core/theme/theme_provider.dart';
import 'package:hamropadhai/features/dashboard/presentation/pages/change_password_screen.dart';
import 'package:hamropadhai/features/auth/presentation/view_model/auth_viewmodel.dart';
import 'package:hamropadhai/features/auth/presentation/pages/login_screen.dart';
import 'package:hamropadhai/core/providers/biometric_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey[500]!;
    final divColor = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);

    final luxAsync = ref.watch(lightSensorProvider);
    final luxValue = themeMode == AppThemeMode.sensor
        ? luxAsync.whenOrNull(data: (lux) => lux)
        : null;

    final biometricEnabled = ref.watch(biometricEnabledProvider);

    // ✅ Get current logged-in username from profileProvider
    // profileProvider returns Map<String, dynamic>
    final profileAsync = ref.watch(profileProvider);
    final currentUsername =
        profileAsync.whenOrNull(data: (p) => p['username'] as String?) ?? '';

    Future<void> handleLogout() async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Log Out',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: TextStyle(color: textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Log Out',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await ref.read(authViewModelProvider.notifier).logout();
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    }

    // ✅ Ask user to enter their password so we can save credentials right now
    Future<String?> promptForPassword() async {
      final controller = TextEditingController();
      bool obscure = true;
      return showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            backgroundColor: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.fingerprint,
                  color: Color(0xFF7C3AED),
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Enter Your Password',
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'To save fingerprint login for "@$currentUsername", please confirm your password:',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  obscureText: obscure,
                  autofocus: true,
                  style: TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Your password',
                    hintStyle: TextStyle(color: textSecondary),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                        color: textSecondary,
                        size: 20,
                      ),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: Text('Cancel', style: TextStyle(color: textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  final pw = controller.text;
                  Navigator.pop(ctx, pw.isEmpty ? null : pw);
                },
                child: const Text('Confirm'),
              ),
            ],
          ),
        ),
      );
    }

    Future<void> handleBiometricToggle(bool value) async {
      final localAuth = LocalAuthentication();

      if (value) {
        // ── Turning ON ──────────────────────────────────────────
        final bool canCheck = await localAuth.canCheckBiometrics;
        final bool isSupported = await localAuth.isDeviceSupported();

        if (!canCheck || !isSupported) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Biometric authentication is not available on this device',
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }

        final List<BiometricType> available = await localAuth
            .getAvailableBiometrics();

        if (available.isEmpty) {
          if (context.mounted) {
            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  'No Fingerprint Found',
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Text(
                  'No fingerprint is enrolled on this device.\n\nPlease go to:\nSettings → Security → Fingerprint\nand add a fingerprint first.',
                  style: TextStyle(color: textSecondary, height: 1.5),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Color(0xFF7C3AED)),
                    ),
                  ),
                ],
              ),
            );
          }
          return;
        }

        // Verify fingerprint first
        bool verified = false;
        try {
          verified = await localAuth.authenticate(
            localizedReason:
                'Verify your fingerprint to enable biometric login',
            options: const AuthenticationOptions(
              biometricOnly: true,
              stickyAuth: true,
            ),
          );
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Biometric error: ${e.toString().replaceFirst('Exception: ', '')}',
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }

        if (!verified) return;
        if (!context.mounted) return;

        // ✅ Enable the toggle first
        await ref.read(biometricEnabledProvider.notifier).setEnabled(true);

        // ✅ If we know the current username, ask for their password to save credentials
        if (currentUsername.isNotEmpty) {
          // Check if already saved
          final existingPassword = await BiometricCredentialStorage.getPassword(
            currentUsername,
          );

          if (existingPassword == null || existingPassword.isEmpty) {
            if (!context.mounted) return;

            // Ask for password to save credentials now
            final password = await promptForPassword();

            if (password != null && password.isNotEmpty && context.mounted) {
              await ref
                  .read(biometricAccountsProvider.notifier)
                  .addAccount(currentUsername, currentUsername);
              await BiometricCredentialStorage.saveCredentials(
                currentUsername,
                password,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '✅ Fingerprint login enabled for @$currentUsername!',
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            } else {
              // User skipped password — toggle is enabled but no account saved yet
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Fingerprint enabled. Log in once with password to fully link your account.',
                    ),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 4),
                  ),
                );
              }
            }
          } else {
            // Credentials already saved — just re-add the account entry
            await ref
                .read(biometricAccountsProvider.notifier)
                .addAccount(currentUsername, currentUsername);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fingerprint login enabled!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        } else {
          // Can't determine username right now
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Fingerprint enabled. Log in once with password to link your account.',
                ),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      } else {
        // ── Turning OFF ─────────────────────────────────────────
        // Just disable — keep saved accounts/credentials intact
        await ref.read(biometricEnabledProvider.notifier).setEnabled(false);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fingerprint login disabled.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(label: 'Appearance', textSecondary: textSecondary),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: divColor),
              ),
              child: Column(
                children: [
                  _ThemeOption(
                    icon: Icons.light_mode_outlined,
                    activeIcon: Icons.light_mode,
                    title: 'Light Mode',
                    subtitle: 'Always use light theme',
                    selected: themeMode == AppThemeMode.light,
                    iconColor: const Color(0xFFF59E0B),
                    iconBg: const Color(0xFFFEF3C7),
                    onTap: () => ref
                        .read(themeModeProvider.notifier)
                        .setMode(AppThemeMode.light),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    divColor: divColor,
                    showDivider: true,
                  ),
                  _ThemeOption(
                    icon: Icons.dark_mode_outlined,
                    activeIcon: Icons.dark_mode,
                    title: 'Dark Mode',
                    subtitle: 'Always use dark theme',
                    selected: themeMode == AppThemeMode.dark,
                    iconColor: const Color(0xFF7C3AED),
                    iconBg: const Color(0xFFEDE9FE),
                    onTap: () => ref
                        .read(themeModeProvider.notifier)
                        .setMode(AppThemeMode.dark),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    divColor: divColor,
                    showDivider: true,
                  ),
                  _ThemeOption(
                    icon: Icons.brightness_auto_outlined,
                    activeIcon: Icons.brightness_auto,
                    title: 'Auto (System)',
                    subtitle: 'Follows your phone\'s system theme',
                    selected: themeMode == AppThemeMode.auto,
                    iconColor: const Color(0xFF3B82F6),
                    iconBg: const Color(0xFFDBEAFE),
                    onTap: () => ref
                        .read(themeModeProvider.notifier)
                        .setMode(AppThemeMode.auto),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    divColor: divColor,
                    showDivider: true,
                  ),
                  _ThemeOption(
                    icon: Icons.sensor_occupied_outlined,
                    activeIcon: Icons.sensor_occupied,
                    title: 'Light Sensor',
                    subtitle: 'Cover sensor → Dark • Uncover → Light',
                    selected: themeMode == AppThemeMode.sensor,
                    iconColor: const Color(0xFF10B981),
                    iconBg: const Color(0xFFD1FAE5),
                    onTap: () => ref
                        .read(themeModeProvider.notifier)
                        .setMode(AppThemeMode.sensor),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    divColor: divColor,
                    showDivider: false,
                  ),
                ],
              ),
            ),

            if (themeMode == AppThemeMode.sensor) ...[
              const SizedBox(height: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5).withOpacity(isDark ? 0.15 : 1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      luxValue != null && luxValue < kDarkLuxThreshold
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      color: const Color(0xFF10B981),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            luxValue != null && luxValue < kDarkLuxThreshold
                                ? '🌑 Dark mode active — sensor covered'
                                : '☀️ Light mode active — sensor uncovered',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFF6EE7B7)
                                  : const Color(0xFF065F46),
                            ),
                          ),
                          if (luxValue != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Light level: ${luxValue.toStringAsFixed(1)} lux  (threshold: ${kDarkLuxThreshold.toInt()} lux)',
                              style: TextStyle(
                                fontSize: 11,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            _SectionLabel(label: 'Account', textSecondary: textSecondary),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: divColor),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen(),
                      ),
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.lock_outline,
                              color: Color(0xFF3B82F6),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Change Password',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Update your account password',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  Divider(
                    height: 1,
                    indent: 72,
                    endIndent: 16,
                    color: divColor,
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: biometricEnabled
                                ? const Color(0xFF7C3AED).withOpacity(0.15)
                                : const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.fingerprint,
                            color: biometricEnabled
                                ? const Color(0xFF7C3AED)
                                : const Color(0xFF7C3AED).withOpacity(0.5),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fingerprint Login',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                biometricEnabled
                                    ? 'Tap fingerprint icon on login screen'
                                    : 'Enable to use fingerprint on login',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: biometricEnabled,
                          onChanged: (val) => handleBiometricToggle(val),
                          activeColor: const Color(0xFF7C3AED),
                        ),
                      ],
                    ),
                  ),

                  Divider(
                    height: 1,
                    indent: 72,
                    endIndent: 16,
                    color: divColor,
                  ),

                  InkWell(
                    onTap: handleLogout,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              color: Colors.red,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Log Out',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Sign out of your account',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _SectionLabel(label: 'About', textSecondary: textSecondary),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: divColor),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.school_outlined,
                    iconColor: const Color(0xFF10B981),
                    iconBg: const Color(0xFFD1FAE5),
                    title: 'App Name',
                    value: 'HamroPadhai',
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    divColor: divColor,
                    showDivider: true,
                  ),
                  _InfoRow(
                    icon: Icons.tag_outlined,
                    iconColor: const Color(0xFF7C3AED),
                    iconBg: const Color(0xFFEDE9FE),
                    title: 'Version',
                    value: '1.0.0',
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    divColor: divColor,
                    showDivider: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color textSecondary;
  const _SectionLabel({required this.label, required this.textSecondary});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 2),
    child: Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: textSecondary,
        letterSpacing: 1,
      ),
    ),
  );
}

class _ThemeOption extends StatelessWidget {
  final IconData icon, activeIcon;
  final String title, subtitle;
  final bool selected;
  final Color iconColor, iconBg;
  final VoidCallback onTap;
  final Color textPrimary, textSecondary, divColor;
  final bool showDivider;

  const _ThemeOption({
    required this.icon,
    required this.activeIcon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.iconColor,
    required this.iconBg,
    required this.onTap,
    required this.textPrimary,
    required this.textSecondary,
    required this.divColor,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: selected ? iconColor : iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    selected ? activeIcon : icon,
                    color: selected ? Colors.white : iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? iconColor : Colors.transparent,
                    border: Border.all(
                      color: selected ? iconColor : textSecondary,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, indent: 72, endIndent: 16, color: divColor),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String title, value;
  final Color textPrimary, textSecondary, divColor;
  final bool showDivider;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.value,
    required this.textPrimary,
    required this.textSecondary,
    required this.divColor,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
              ),
              Text(value, style: TextStyle(fontSize: 14, color: textSecondary)),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, indent: 72, endIndent: 16, color: divColor),
      ],
    );
  }
}
