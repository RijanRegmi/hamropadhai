import 'package:hive/hive.dart';

class AuthLocalDatasource {
  static const String userBoxName = 'users';

  Future<void> signup({
    required String name,
    required String email,
    required String password,
    required String gender,
  }) async {
    final box = Hive.box(userBoxName);

    await box.put(email, {
      "name": name,
      "email": email,
      "password": password,
      "gender": gender,
    });
  }

  Future<bool> login({required String email, required String password}) async {
    final box = Hive.box(userBoxName);
    final user = box.get(email);

    if (user == null) return false;

    return user['password'] == password;
  }

  Future<void> saveToken(String token) async {
    final box = Hive.box(userBoxName);
    await box.put('token', token);
    await box.put('isLoggedIn', true);
  }

  Future<void> logout() async {
    final box = Hive.box(userBoxName);
    await box.put('isLoggedIn', false);
    await box.delete('token');
  }

  Future<bool> isLoggedIn() async {
    final box = Hive.box(userBoxName);
    return box.get('isLoggedIn', defaultValue: false);
  }
}
