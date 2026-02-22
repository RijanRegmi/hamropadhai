// biometric_provider.dart
// Place at: lib/core/providers/biometric_provider.dart

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kBiometricEnabled = 'biometric_login_enabled';
const _kBiometricAccounts = 'biometric_saved_accounts';
const _kBiometricCredentials = 'biometric_credentials';

// ── Biometric enabled toggle ──────────────────────────────────────────────────

final biometricEnabledProvider = StateNotifierProvider<BiometricNotifier, bool>(
  (ref) => BiometricNotifier(),
);

class BiometricNotifier extends StateNotifier<bool> {
  BiometricNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_kBiometricEnabled) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBiometricEnabled, value);
  }
}

// ── Saved biometric accounts ──────────────────────────────────────────────────

final biometricAccountsProvider =
    StateNotifierProvider<BiometricAccountsNotifier, List<Map<String, String>>>(
      (ref) => BiometricAccountsNotifier(),
    );

class BiometricAccountsNotifier
    extends StateNotifier<List<Map<String, String>>> {
  BiometricAccountsNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kBiometricAccounts);
    if (raw != null) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      state = decoded.map((e) => Map<String, String>.from(e)).toList();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBiometricAccounts, jsonEncode(state));
  }

  Future<void> addAccount(String username, String displayName) async {
    final exists = state.any((a) => a['username'] == username);
    if (!exists) {
      state = [
        ...state,
        {'username': username, 'displayName': displayName},
      ];
      await _save();
    }
  }

  // Removes ONE account + its credentials
  Future<void> removeAccount(String username) async {
    state = state.where((a) => a['username'] != username).toList();
    await _save();
    await BiometricCredentialStorage.removeCredentials(username);
  }

  // ✅ Only called when user explicitly wants to wipe everything
  Future<void> clearAll() async {
    for (final account in state) {
      final username = account['username'];
      if (username != null) {
        await BiometricCredentialStorage.removeCredentials(username);
      }
    }
    state = [];
    await _save();
  }

  bool hasAccount(String username) {
    return state.any((a) => a['username'] == username);
  }
}

// ── Credential storage ────────────────────────────────────────────────────────

class BiometricCredentialStorage {
  static Future<void> saveCredentials(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kBiometricCredentials);
    final Map<String, dynamic> all = raw != null
        ? Map<String, dynamic>.from(jsonDecode(raw))
        : {};
    all[username] = password;
    await prefs.setString(_kBiometricCredentials, jsonEncode(all));
  }

  static Future<String?> getPassword(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kBiometricCredentials);
    if (raw == null) return null;
    final Map<String, dynamic> all = Map<String, dynamic>.from(jsonDecode(raw));
    return all[username] as String?;
  }

  static Future<void> removeCredentials(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kBiometricCredentials);
    if (raw == null) return;
    final Map<String, dynamic> all = Map<String, dynamic>.from(jsonDecode(raw));
    all.remove(username);
    await prefs.setString(_kBiometricCredentials, jsonEncode(all));
  }
}
