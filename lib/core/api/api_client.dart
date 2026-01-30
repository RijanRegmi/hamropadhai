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
      print('POST Request to: $url');
      print('Request body: ${jsonEncode(body)}');

      final response = await _client
          .post(
            Uri.parse(url),
            headers: {"Content-Type": "application/json", ...?headers},
            body: jsonEncode(body),
          )
          .timeout(
            ApiEndpoints.connectionTimeout,
            onTimeout: () {
              throw TimeoutException(
                'Connection timeout. Please check your internet connection and try again.',
              );
            },
          );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      } else {
        throw Exception(decoded['message'] ?? "Something went wrong");
      }
    } on TimeoutException catch (e) {
      print('Timeout error: $e');
      throw Exception(
        'Request timed out. Please check your internet connection.',
      );
    } on SocketException catch (e) {
      print('Socket error: $e');
      throw Exception(
        'Cannot connect to server. Please check if the server is running and your network connection.',
      );
    } on FormatException catch (e) {
      print('Format error: $e');
      throw Exception('Invalid response from server.');
    } catch (e) {
      print('Error in post: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      print('GET Request to: $url');

      final response = await _client
          .get(
            Uri.parse(url),
            headers: {"Content-Type": "application/json", ...?headers},
          )
          .timeout(
            ApiEndpoints.connectionTimeout,
            onTimeout: () {
              throw TimeoutException(
                'Connection timeout. Please check your internet connection and try again.',
              );
            },
          );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      } else {
        throw Exception(decoded['message'] ?? "Something went wrong");
      }
    } on TimeoutException catch (e) {
      print('Timeout error: $e');
      throw Exception(
        'Request timed out. Please check your internet connection.',
      );
    } on SocketException catch (e) {
      print('Socket error: $e');
      throw Exception(
        'Cannot connect to server. Please check if the server is running and your network connection.',
      );
    } on FormatException catch (e) {
      print('Format error: $e');
      throw Exception('Invalid response from server.');
    } catch (e) {
      print('Error in get: $e');
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
      print('Uploading image from path: $imagePath');

      final request = http.MultipartRequest('POST', Uri.parse(url));

      if (headers != null) {
        request.headers.addAll(headers);
      }

      final file = File(imagePath);

      if (!await file.exists()) {
        throw Exception('File does not exist at path: $imagePath');
      }

      final fileSize = await file.length();
      print('File size: $fileSize bytes');

      final mimeType = lookupMimeType(imagePath);
      print('Detected MIME type: $mimeType');

      final multipartFile = await http.MultipartFile.fromPath(
        fieldName,
        imagePath,
        contentType: mimeType != null
            ? MediaType.parse(mimeType)
            : MediaType('image', 'jpeg'),
      );

      print('Adding file to request: ${multipartFile.filename}');
      print('Content-Type: ${multipartFile.contentType}');

      request.files.add(multipartFile);

      print('Sending request to: $url');

      final streamedResponse = await request.send().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Image upload timed out.');
        },
      );

      print('Response status code: ${streamedResponse.statusCode}');

      final response = await http.Response.fromStream(streamedResponse);

      print('Response body: ${response.body}');

      final decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      } else {
        throw Exception(decoded['message'] ?? "Upload failed");
      }
    } on TimeoutException catch (e) {
      print('Timeout error: $e');
      throw Exception('Upload timed out. Please try again.');
    } on SocketException catch (e) {
      print('Socket error: $e');
      throw Exception('Cannot connect to server. Please check your network.');
    } catch (e) {
      print('Error in uploadImage: $e');
      rethrow;
    }
  }
}
