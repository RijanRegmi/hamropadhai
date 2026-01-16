import 'package:hamropadhai/core/api/api_client.dart';
import 'package:hamropadhai/core/api/api_endpoints.dart';

abstract class AuthRemoteDataSource {
  Future<void> signup({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String gender,
  });

  Future<String> login({required String email, required String password});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl(this.apiClient);

  @override
  Future<void> signup({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String gender,
  }) async {
    await apiClient.post(
      ApiEndpoints.baseUrl + ApiEndpoints.signup,
      body: {
        "fullName": fullName,
        "email": email,
        "phone": phone,
        "password": password,
        "gender": gender,
      },
    );
  }

  @override
  Future<String> login({
    required String email,
    required String password,
  }) async {
    final data = await apiClient.post(
      ApiEndpoints.baseUrl + ApiEndpoints.login,
      body: {"email": email, "password": password},
    );

    return data["token"];
  }
}
