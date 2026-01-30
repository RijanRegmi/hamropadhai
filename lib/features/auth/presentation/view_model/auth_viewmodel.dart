import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';

final authViewModelProvider = StateNotifierProvider<AuthViewModel, bool>((ref) {
  return AuthViewModel(ref.read(authRepositoryProvider), ref);
});

final profileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.read(authRepositoryProvider);
  return await repository.getProfile();
});

class AuthViewModel extends StateNotifier<bool> {
  final AuthRepository repository;
  final Ref ref;

  AuthViewModel(this.repository, this.ref) : super(false);

  Future<void> signup({
    required String fullName,
    required String username,
    required String email,
    required String phone,
    required String password,
    required String gender,
  }) async {
    try {
      state = true;
      await repository.signup(
        fullName: fullName,
        username: username,
        email: email,
        phone: phone,
        password: password,
        gender: gender,
      );
    } finally {
      state = false;
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    try {
      state = true;
      await repository.login(username: username, password: password);

      ref.invalidate(profileProvider);
    } finally {
      state = false;
    }
  }

  Future<String> uploadProfileImage(String imagePath) async {
    try {
      state = true;
      return await repository.uploadProfileImage(imagePath);
    } finally {
      state = false;
    }
  }

  Future<void> logout() async {
    await repository.logout();

    ref.invalidate(profileProvider);
  }
}
