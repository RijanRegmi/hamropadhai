import 'package:http/http.dart' as http;
import 'dart:convert';

class NoticeRemoteDatasource {
  final http.Client client;
  static const _base = 'http://10.0.2.2:5050';

  NoticeRemoteDatasource(this.client);

  Future<List<Map<String, dynamic>>> getMyNotices(String token) async {
    final res = await client
        .get(Uri.parse('$_base/api/notices/my'), headers: _headers(token))
        .timeout(const Duration(seconds: 10));

    final body = _decode(res);
    return List<Map<String, dynamic>>.from(body['data'] ?? []);
  }

  Future<int> getUnreadCount(String token) async {
    final res = await client
        .get(
          Uri.parse('$_base/api/notices/unread-count'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 10));

    final body = _decode(res);
    return (body['data']?['unreadCount'] as int?) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getPinnedNotices(String token) async {
    final res = await client
        .get(Uri.parse('$_base/api/notices/pinned'), headers: _headers(token))
        .timeout(const Duration(seconds: 10));

    final body = _decode(res);
    return List<Map<String, dynamic>>.from(body['data'] ?? []);
  }

  Future<Map<String, dynamic>> getNoticeById(
    String token,
    String noticeId,
  ) async {
    final res = await client
        .get(
          Uri.parse('$_base/api/notices/$noticeId'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 10));

    final body = _decode(res);
    return Map<String, dynamic>.from(body['data'] ?? {});
  }

  Future<void> markAsRead(String token, String noticeId) async {
    await client
        .post(
          Uri.parse('$_base/api/notices/$noticeId/mark-read'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 10));
  }

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  Map<String, dynamic> _decode(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(body['message'] ?? 'Request failed (${res.statusCode})');
    }
    return body;
  }
}
