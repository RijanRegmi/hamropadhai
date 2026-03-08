import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:hamropadhai/core/api/api_endpoints.dart';

class RoutineRemoteDatasource {
  final http.Client _client;

  RoutineRemoteDatasource(this._client);

  Future<String> get _baseUrl async =>
      '${await ApiEndpoints.imageBaseUrl}/api/routines';

  Future<Map<String, dynamic>> getMyRoutine(String token) async {
    final baseUrl = await _baseUrl;
    final response = await _client
        .get(
          Uri.parse('$baseUrl/my'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));

    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded['data'] as Map<String, dynamic>;
    }
    throw Exception(decoded['message'] ?? 'Failed to fetch routine');
  }
}
