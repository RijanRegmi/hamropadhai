import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hamropadhai/core/theme/theme_provider.dart';
import 'package:hamropadhai/features/dashboard/presentation/pages/change_password_screen.dart';
import 'package:hamropadhai/features/auth/presentation/view_model/auth_viewmodel.dart';
import 'package:hamropadhai/features/auth/presentation/pages/login_screen.dart';

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
              child: Column(
                children: [
                  // Change Password
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

                  // Log Out
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
