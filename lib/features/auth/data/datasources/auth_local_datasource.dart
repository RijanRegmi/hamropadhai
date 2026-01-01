import 'package:hive/hive.dart';
import '../../../../core/constants/hive_table_constant.dart';
import '../models/user_hive_model.dart';

class AuthLocalDatasource {
  final Box<UserHiveModel> box = Hive.box<UserHiveModel>(
    HiveTableConstant.userBox,
  );

  Future<void> signup(UserHiveModel user) async {
    await box.put(user.email, user);
  }

  Future<UserHiveModel?> login(String email, String password) async {
    final user = box.get(email);
    if (user == null) return null;
    if (user.password != password) return null;
    return user;
  }
}
