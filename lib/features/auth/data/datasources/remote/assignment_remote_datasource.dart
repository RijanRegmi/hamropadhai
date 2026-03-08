import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:hamropadhai/core/api/api_endpoints.dart';

class AssignmentRemoteDatasource {
  final http.Client _client;

  AssignmentRemoteDatasource(this._client);

  Future<String> get _baseUrl async =>
      '${await ApiEndpoints.imageBaseUrl}/api/assignments';

  Future<List<Map<String, dynamic>>> getMyAssignments(String token) async {
    final baseUrl = await _baseUrl;
    final res = await _client
        .get(
          Uri.parse('$baseUrl/my'),
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
    final baseUrl = await _baseUrl;
    final res = await _client
        .get(
          Uri.parse('$baseUrl/pending'),
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
    final baseUrl = await _baseUrl;
    final res = await _client
        .get(
          Uri.parse('$baseUrl/submitted'),
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
    final baseUrl = await _baseUrl;
    final res = await _client
        .get(
          Uri.parse('$baseUrl/graded'),
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
    final baseUrl = await _baseUrl;
    final res = await _client
        .get(
          Uri.parse('$baseUrl/history'),
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
    final baseUrl = await _baseUrl;
    final res = await _client
        .get(
          Uri.parse('$baseUrl/$id'),
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
    final baseUrl = await _baseUrl;
    final res = await _client
        .post(
          Uri.parse('$baseUrl/$id/submit'),
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
