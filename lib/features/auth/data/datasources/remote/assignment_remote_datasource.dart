import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class AssignmentRemoteDatasource {
  final http.Client _client;
  static const String _baseUrl = 'http://10.0.2.2:5050/api/assignments';

  AssignmentRemoteDatasource(this._client);

  Future<List<Map<String, dynamic>>> getMyAssignments(String token) async {
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
      final data = decoded['data'] as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception(decoded['message'] ?? 'Failed to fetch assignments');
  }
}
