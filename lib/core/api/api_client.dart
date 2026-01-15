import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final http.Client _client;

  ApiClient(this._client);

  Future<Map<String, dynamic>> post(
    String url, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    final response = await _client.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json", ...?headers},
      body: jsonEncode(body),
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    } else {
      throw Exception(decoded['message'] ?? "Something went wrong");
    }
  }
}
