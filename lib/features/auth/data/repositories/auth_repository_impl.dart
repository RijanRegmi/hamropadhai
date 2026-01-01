import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../models/user_hive_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDatasource datasource;

  AuthRepositoryImpl(this.datasource);

  @override
  Future<void> signup(UserEntity user) async {
    final model = UserHiveModel.fromEntity(user);
    await datasource.signup(model);
  }

  @override
  Future<UserEntity?> login(String email, String password) async {
    final model = await datasource.login(email, password);
    return model?.toEntity();
  }
}
