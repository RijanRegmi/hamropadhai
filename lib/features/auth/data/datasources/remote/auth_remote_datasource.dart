import 'package:hamropadhai/core/api/api_client.dart';
import 'package:hamropadhai/core/api/api_endpoints.dart';

abstract class AuthRemoteDataSource {
  Future<void> signup({
    required String fullName,
    required String username,
    required String email,
    required String phone,
    required String password,
    required String gender,
  });

  Future<String> login({required String username, required String password});

  Future<Map<String, dynamic>> getProfile(String token);

  Future<String> uploadProfileImage(String token, String imagePath);

  Future<Map<String, dynamic>> updateProfile(
    String token,
    Map<String, dynamic> data,
  );
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl(this.apiClient);

  @override
  Future<void> signup({
    required String fullName,
    required String username,
    required String email,
    required String phone,
    required String password,
    required String gender,
  }) async {
    final base = await ApiEndpoints.baseUrl;
    await apiClient.post(
      base + ApiEndpoints.signup,
      body: {
        "fullName": fullName,
        "username": username,
        "email": email,
        "phone": phone,
        "password": password,
        "gender": gender,
      },
    );
  }

  @override
  Future<String> login({
    required String username,
    required String password,
  }) async {
    final base = await ApiEndpoints.baseUrl;
    final response = await apiClient.post(
      base + ApiEndpoints.login,
      body: {"username": username, "password": password},
    );

    if (response["success"] == true &&
        response["data"] != null &&
        response["data"]["token"] != null) {
      return response["data"]["token"] as String;
    }

    throw Exception("Token not found in response");
  }

  @override
  Future<Map<String, dynamic>> getProfile(String token) async {
    final base = await ApiEndpoints.baseUrl;
    final data = await apiClient.get(
      base + ApiEndpoints.profile,
      headers: {"Authorization": "Bearer $token"},
    );
    return data["data"];
  }

  @override
  Future<String> uploadProfileImage(String token, String imagePath) async {
    final base = await ApiEndpoints.baseUrl;
    final data = await apiClient.uploadImage(
      base + ApiEndpoints.uploadProfileImage,
      imagePath: imagePath,
      fieldName: "profileImage",
      headers: {"Authorization": "Bearer $token"},
    );

    if (data["success"] == true &&
        data["data"] != null &&
        data["data"]["profileImage"] != null) {
      return data["data"]["profileImage"] as String;
    }

    throw Exception("Profile image URL not found in response");
  }

  @override
  Future<Map<String, dynamic>> updateProfile(
    String token,
    Map<String, dynamic> data,
  ) async {
    final base = await ApiEndpoints.baseUrl;
    final response = await apiClient.put(
      base + ApiEndpoints.updateProfile,
      body: data,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response["success"] == true && response["data"] != null) {
      return response["data"];
    }

    throw Exception(response["message"] ?? "Failed to update profile");
  }
}
