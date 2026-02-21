import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:hamropadhai/core/api/api_endpoints.dart';

class RoutineRemoteDatasource {
  final http.Client _client;

  RoutineRemoteDatasource(this._client);

  String get _baseUrl => '${ApiEndpoints.imageBaseUrl}/api/routines';

  Future<Map<String, dynamic>> getMyRoutine(String token) async {
    final response = await _client
        .get(
          Uri.parse('$_baseUrl/my'),
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
