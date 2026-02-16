import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'dart:async';
import 'package:mime/mime.dart';
import 'api_endpoints.dart';

class ApiClient {
  final http.Client _client;

  ApiClient(this._client);

  Future<Map<String, dynamic>> post(
    String url, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse(url),
            headers: {"Content-Type": "application/json", ...?headers},
            body: jsonEncode(body),
          )
          .timeout(ApiEndpoints.connectionTimeout);

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      } else {
        throw Exception(decoded['message'] ?? "Something went wrong");
      }
    } on TimeoutException {
      throw Exception(
        'Request timed out. Please check your internet connection.',
      );
    } on SocketException {
      throw Exception('Cannot connect to server.');
    } on FormatException {
      throw Exception('Invalid response from server.');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> put(
    String url, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client
          .put(
            Uri.parse(url),
            headers: {"Content-Type": "application/json", ...?headers},
            body: jsonEncode(body),
          )
          .timeout(ApiEndpoints.connectionTimeout);

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      } else {
        throw Exception(decoded['message'] ?? "Something went wrong");
      }
    } on TimeoutException {
      throw Exception(
        'Request timed out. Please check your internet connection.',
      );
    } on SocketException {
      throw Exception('Cannot connect to server.');
    } on FormatException {
      throw Exception('Invalid response from server.');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client
          .get(
            Uri.parse(url),
            headers: {"Content-Type": "application/json", ...?headers},
          )
          .timeout(ApiEndpoints.connectionTimeout);

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      } else {
        throw Exception(decoded['message'] ?? "Something went wrong");
      }
    } on TimeoutException {
      throw Exception(
        'Request timed out. Please check your internet connection.',
      );
    } on SocketException {
      throw Exception('Cannot connect to server.');
    } on FormatException {
      throw Exception('Invalid response from server.');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadImage(
    String url, {
    required String imagePath,
    required String fieldName,
    Map<String, String>? headers,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));

      if (headers != null) {
        request.headers.addAll(headers);
      }

      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('File does not exist at path: $imagePath');
      }

      final mimeType = lookupMimeType(imagePath);
      final multipartFile = await http.MultipartFile.fromPath(
        fieldName,
        imagePath,
        contentType: mimeType != null
            ? MediaType.parse(mimeType)
            : MediaType('image', 'jpeg'),
      );

      request.files.add(multipartFile);

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Image upload timed out.'),
      );

      final response = await http.Response.fromStream(streamedResponse);
      final decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      } else {
        throw Exception(decoded['message'] ?? "Upload failed");
      }
    } on TimeoutException {
      throw Exception('Upload timed out. Please try again.');
    } on SocketException {
      throw Exception('Cannot connect to server. Please check your network.');
    } catch (e) {
      rethrow;
    }
  }
}
