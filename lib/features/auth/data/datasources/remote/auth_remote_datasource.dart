import 'package:hamropadhai/core/api/api_client.dart';
import 'package:hamropadhai/core/api/api_endpoints.dart';

class AuthRemoteDataSource {
  final ApiClient client;

  AuthRemoteDataSource(this.client);

  Future<void> signup({
    required String name,
    required String email,
    required String password,
    required String gender,
  }) async {
    await client.post(
      ApiEndpoints.baseUrl + ApiEndpoints.signup,
      body: {
        "name": name,
        "email": email,
        "password": password,
        "gender": gender,
      },
    );
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final data = await client.post(
      ApiEndpoints.baseUrl + ApiEndpoints.login,
      body: {"email": email, "password": password},
    );

    return data['token'];
  }
}
