import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUserUsecase {
  final AuthRepository repository;

  LoginUserUsecase(this.repository);

  Future<UserEntity?> call(String email, String password) {
    return repository.login(email, password);
  }
}
