import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';

/// Loading state: true = loading
final authViewModelProvider = StateNotifierProvider<AuthViewModel, bool>((ref) {
  return AuthViewModel(ref.read(authRepositoryProvider));
});

class AuthViewModel extends StateNotifier<bool> {
  final AuthRepository repository;

  AuthViewModel(this.repository) : super(false);

  Future<void> login({required String email, required String password}) async {
    try {
      state = true;
      await repository.login(email: email, password: password);
    } finally {
      state = false;
    }
  }

  Future<void> signup({
    required String name,
    required String email,
    required String password,
    required String gender,
  }) async {
    try {
      state = true;
      await repository.signup(
        name: name,
        email: email,
        password: password,
        gender: gender,
      );
    } finally {
      state = false;
    }
  }

  Future<void> logout() async {
    await repository.logout();
  }
}
