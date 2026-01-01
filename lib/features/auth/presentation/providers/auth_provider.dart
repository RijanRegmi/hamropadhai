import 'package:flutter/material.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_user_usecase.dart';
import '../../domain/usecases/signup_user_usecase.dart';

class AuthProvider extends ChangeNotifier {
  final SignupUserUsecase signupUserUsecase;
  final LoginUserUsecase loginUserUsecase;

  AuthProvider({
    required this.signupUserUsecase,
    required this.loginUserUsecase,
  });

  Future<void> signup(UserEntity user) async {
    await signupUserUsecase(user);
  }

  Future<UserEntity?> login(String email, String password) async {
    return await loginUserUsecase(email, password);
  }
}
