import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignupUserUsecase {
  final AuthRepository repository;

  SignupUserUsecase(this.repository);

  Future<void> call(UserEntity user) {
    return repository.signup(user);
  }
}
