import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:hamropadhai/core/theme/theme_provider.dart';
import 'package:hamropadhai/core/api/api_endpoints.dart';
import 'package:hamropadhai/features/auth/presentation/providers/auth_token_provider.dart';

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
            // ── APPEARANCE SECTION ────────────────────────────────
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

            // ── Live sensor reading ───────────────────────────────
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

            // ── ACCOUNT SECTION ───────────────────────────────────
            _SectionLabel(label: 'Account', textSecondary: textSecondary),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: divColor),
              ),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                ),
                borderRadius: BorderRadius.circular(16),
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
            ),

            const SizedBox(height: 24),

            // ── ABOUT SECTION ─────────────────────────────────────
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

// ── Change Password Screen ────────────────────────────────────────────────────
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _loading = false;

  @override
  void dispose() {
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final token = await ref.read(authTokenProvider.future);
      if (token == null) throw Exception('Not logged in');

      final res = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/change-password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'oldPassword': _oldPasswordCtrl.text.trim(),
          'newPassword': _newPasswordCtrl.text.trim(),
        }),
      );

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && body['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password changed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // ✅ Show backend error message (e.g. "Old password is incorrect")
        throw Exception(body['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey[500]!;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final divColor = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Change Password',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Info banner ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE).withOpacity(isDark ? 0.15 : 1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF7C3AED).withOpacity(0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF7C3AED),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Enter your current password to verify your identity, then set your new password.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFFC4B5FD)
                              : const Color(0xFF5B21B6),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Password fields card ────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: divColor),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Old password
                    _PasswordField(
                      controller: _oldPasswordCtrl,
                      label: 'Current Password',
                      hint: 'Enter your current password',
                      show: _showOld,
                      onToggle: () => setState(() => _showOld = !_showOld),
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      isDark: isDark,
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Current password is required';
                        return null;
                      },
                    ),

                    Divider(height: 24, color: divColor),

                    // New password
                    _PasswordField(
                      controller: _newPasswordCtrl,
                      label: 'New Password',
                      hint: 'Enter your new password',
                      show: _showNew,
                      onToggle: () => setState(() => _showNew = !_showNew),
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      isDark: isDark,
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'New password is required';
                        if (v.length < 6)
                          return 'Password must be at least 6 characters';
                        if (v == _oldPasswordCtrl.text)
                          return 'New password must be different from current';
                        return null;
                      },
                    ),

                    Divider(height: 24, color: divColor),

                    // Confirm password
                    _PasswordField(
                      controller: _confirmPasswordCtrl,
                      label: 'Confirm New Password',
                      hint: 'Re-enter your new password',
                      show: _showConfirm,
                      onToggle: () =>
                          setState(() => _showConfirm = !_showConfirm),
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      isDark: isDark,
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Please confirm your new password';
                        if (v != _newPasswordCtrl.text)
                          return 'Passwords do not match';
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Submit button ───────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Change Password',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Password field widget ─────────────────────────────────────────────────────
class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final bool show, isDark;
  final VoidCallback onToggle;
  final Color textPrimary, textSecondary;
  final String? Function(String?) validator;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.show,
    required this.onToggle,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !show,
          validator: validator,
          style: TextStyle(color: textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: textSecondary, fontSize: 14),
            filled: true,
            fillColor: isDark
                ? const Color(0xFF2A2A2A)
                : const Color(0xFFF8F8F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF7C3AED),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                show
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: textSecondary,
                size: 20,
              ),
              onPressed: onToggle,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────
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
