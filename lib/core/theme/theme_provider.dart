import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:light_sensor/light_sensor.dart';

// ── Theme mode enum ───────────────────────────────────────────────────────────
enum AppThemeMode { light, dark, auto, sensor }

// Threshold: below this lux = dark mode triggered
const double kDarkLuxThreshold = 10.0;

// ── Raw lux stream — always running, not conditional ─────────────────────────
// ✅ This starts immediately when the app launches, regardless of selected mode
final lightSensorProvider = StreamProvider<double>((ref) async* {
  final hasSensor = await LightSensor.hasSensor;
  dev.log('💡 hasSensor: $hasSensor');
  if (hasSensor != true) return;
  dev.log('✅ Light sensor stream starting...');
  await for (final lux in LightSensor.lightSensorStream) {
    dev.log('💡 Lux: $lux');
    yield lux.toDouble();
  }
});

// ── Theme notifier ────────────────────────────────────────────────────────────
class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  ThemeModeNotifier() : super(AppThemeMode.auto) {
    _load();
  }

  static const _key = 'app_theme_mode';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    switch (prefs.getString(_key)) {
      case 'light':
        state = AppThemeMode.light;
        break;
      case 'dark':
        state = AppThemeMode.dark;
        break;
      case 'sensor':
        state = AppThemeMode.sensor;
        break;
      default:
        state = AppThemeMode.auto;
    }
  }

  Future<void> setMode(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, AppThemeMode>(
      (_) => ThemeModeNotifier(),
    );

// ── Resolved ThemeMode provider ───────────────────────────────────────────────
// ✅ Always watches lightSensorProvider so the stream is always alive
// When mode == sensor, uses lux value. Otherwise uses manual setting.
final resolvedThemeModeProvider = Provider<ThemeMode>((ref) {
  final mode = ref.watch(themeModeProvider);

  // ✅ Always watch the sensor stream — this keeps it alive and reactive
  final luxAsync = ref.watch(lightSensorProvider);

  if (mode == AppThemeMode.sensor) {
    return luxAsync.when(
      data: (lux) {
        dev.log(
          '🌓 Sensor mode: lux=$lux → ${lux < kDarkLuxThreshold ? "DARK" : "LIGHT"}',
        );
        return lux < kDarkLuxThreshold ? ThemeMode.dark : ThemeMode.light;
      },
      loading: () => ThemeMode.light,
      error: (e, _) {
        dev.log('❌ Sensor error: $e');
        return ThemeMode.light;
      },
    );
  }

  switch (mode) {
    case AppThemeMode.light:
      return ThemeMode.light;
    case AppThemeMode.dark:
      return ThemeMode.dark;
    case AppThemeMode.auto:
      return ThemeMode.system;
    default:
      return ThemeMode.system;
  }
});

// ── App Themes ────────────────────────────────────────────────────────────────
ThemeData lightTheme() => ThemeData(
  brightness: Brightness.light,
  colorSchemeSeed: const Color(0xFF7C3AED),
  scaffoldBackgroundColor: const Color(0xFFF2F3F7),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Color(0xFF1A1A1A),
    elevation: 0,
    surfaceTintColor: Colors.transparent,
  ),
  cardColor: Colors.white,
  dividerColor: const Color(0xFFE5E7EB),
  useMaterial3: true,
);

ThemeData darkTheme() => ThemeData(
  brightness: Brightness.dark,
  colorSchemeSeed: const Color(0xFF7C3AED),
  scaffoldBackgroundColor: const Color(0xFF0F0F0F),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1A1A1A),
    foregroundColor: Colors.white,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
  ),
  cardColor: const Color(0xFF1E1E1E),
  dividerColor: const Color(0xFF2E2E2E),
  useMaterial3: true,
);
