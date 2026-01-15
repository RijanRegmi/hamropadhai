import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:hamropadhai/core/services/connectivity/network_info.dart';
import 'package:hamropadhai/core/api/api_client.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../datasources/remote/auth_remote_datasource.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    networkInfo: ref.read(networkInfoProvider),
    remote: AuthRemoteDataSource(ApiClient(http.Client())),
    local: AuthLocalDatasource(),
  );
});

class AuthRepository {
  final INetworkInfo networkInfo;
  final AuthRemoteDataSource remote;
  final AuthLocalDatasource local;

  AuthRepository({
    required this.networkInfo,
    required this.remote,
    required this.local,
  });

  Future<void> signup({
    required String name,
    required String email,
    required String password,
    required String gender,
  }) async {
    if (await networkInfo.isConnected) {
      await remote.signup(
        name: name,
        email: email,
        password: password,
        gender: gender,
      );
    } else {
      await local.signup(
        name: name,
        email: email,
        password: password,
        gender: gender,
      );
    }
  }

  Future<void> login({required String email, required String password}) async {
    if (await networkInfo.isConnected) {
      final token = await remote.login(email: email, password: password);

      await local.saveToken(token);
    } else {
      final success = await local.login(email: email, password: password);

      if (!success) {
        throw Exception("Invalid credentials (offline)");
      }
    }
  }

  Future<void> logout() async {
    await local.logout();
  }

  Future<bool> isLoggedIn() async {
    return local.isLoggedIn();
  }
}
