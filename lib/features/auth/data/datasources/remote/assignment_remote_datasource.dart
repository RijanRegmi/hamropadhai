import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class AssignmentRemoteDatasource {
  final http.Client _client;
  static const String _baseUrl = 'http://10.0.2.2:5050/api/assignments';

  AssignmentRemoteDatasource(this._client);

  Future<List<Map<String, dynamic>>> getMyAssignments(String token) async {
    final res = await _client
        .get(
          Uri.parse('$_baseUrl/my'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));
    final decoded = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return (decoded['data'] as List).cast<Map<String, dynamic>>();
    }
    throw Exception(decoded['message'] ?? 'Failed to fetch assignments');
  }

  Future<List<Map<String, dynamic>>> getPendingAssignments(String token) async {
    final res = await _client
        .get(
          Uri.parse('$_baseUrl/pending'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));
    final decoded = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return (decoded['data'] as List).cast<Map<String, dynamic>>();
    }
    throw Exception(
      decoded['message'] ?? 'Failed to fetch pending assignments',
    );
  }

  Future<List<Map<String, dynamic>>> getSubmittedAssignments(
    String token,
  ) async {
    final res = await _client
        .get(
          Uri.parse('$_baseUrl/submitted'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));
    final decoded = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return (decoded['data'] as List).cast<Map<String, dynamic>>();
    }
    throw Exception(
      decoded['message'] ?? 'Failed to fetch submitted assignments',
    );
  }

  Future<List<Map<String, dynamic>>> getGradedAssignments(String token) async {
    final res = await _client
        .get(
          Uri.parse('$_baseUrl/graded'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));
    final decoded = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return (decoded['data'] as List).cast<Map<String, dynamic>>();
    }
    throw Exception(decoded['message'] ?? 'Failed to fetch graded assignments');
  }

  Future<List<Map<String, dynamic>>> getHistoryAssignments(String token) async {
    final res = await _client
        .get(
          Uri.parse('$_baseUrl/history'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));
    final decoded = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return (decoded['data'] as List).cast<Map<String, dynamic>>();
    }
    throw Exception(decoded['message'] ?? 'Failed to fetch history');
  }

  Future<Map<String, dynamic>> getAssignmentById(
    String token,
    String id,
  ) async {
    final res = await _client
        .get(
          Uri.parse('$_baseUrl/$id'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));
    final decoded = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded['data'] as Map<String, dynamic>;
    }
    throw Exception(decoded['message'] ?? 'Failed to fetch assignment');
  }

  Future<Map<String, dynamic>> submitAssignment(
    String token,
    String id,
    String? textContent,
  ) async {
    final res = await _client
        .post(
          Uri.parse('$_baseUrl/$id/submit'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'textContent': textContent ?? ''}),
        )
        .timeout(const Duration(seconds: 10));
    final decoded = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded['data'] as Map<String, dynamic>;
    }
    throw Exception(decoded['message'] ?? 'Failed to submit assignment');
  }
}
