import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';

final authViewModelProvider = StateNotifierProvider<AuthViewModel, bool>((ref) {
  return AuthViewModel(ref.read(authRepositoryProvider));
});

class AuthViewModel extends StateNotifier<bool> {
  final AuthRepository repository;

  AuthViewModel(this.repository) : super(false);

  Future<void> signup({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String gender,
  }) async {
    try {
      state = true;
      await repository.signup(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        gender: gender,
      );
    } finally {
      state = false;
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      state = true;
      await repository.login(email: email, password: password);
    } finally {
      state = false;
    }
  }

  Future<void> logout() async {
    await repository.logout();
  }
}
