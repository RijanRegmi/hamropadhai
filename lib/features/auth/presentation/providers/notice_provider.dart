import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../auth/presentation/providers/auth_token_provider.dart';

const _base = 'http://10.0.2.2:5050';

final _noticeRemoteProvider = Provider((ref) => _NoticeRemote());

class _NoticeRemote {
  Future<List<Map<String, dynamic>>> getMyNotices(String token) async {
    final res = await http
        .get(
          Uri.parse('$_base/api/notices/my'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 10));
    final body = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return List<Map<String, dynamic>>.from(body['data'] ?? []);
    }
    throw Exception(body['message'] ?? 'Failed to fetch notices');
  }

  Future<Map<String, dynamic>> markAsRead(String token, String noticeId) async {
    final res = await http
        .post(
          Uri.parse('$_base/api/notices/$noticeId/mark-read'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 10));
    final body = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return Map<String, dynamic>.from(body['data'] ?? {});
    }
    throw Exception(body['message'] ?? 'Failed to mark as read');
  }

  Future<Map<String, dynamic>> getUnreadCount(String token) async {
    final res = await http
        .get(
          Uri.parse('$_base/api/notices/unread-count'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 10));
    final body = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return Map<String, dynamic>.from(body['data'] ?? {});
    }
    return {'unreadCount': 0};
  }
}

final myNoticesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final token = await ref.watch(authTokenProvider.future);
  if (token == null) throw Exception('Not logged in');
  return ref.read(_noticeRemoteProvider).getMyNotices(token);
});

final unreadCountProvider = FutureProvider<int>((ref) async {
  final token = await ref.watch(authTokenProvider.future);
  if (token == null) return 0;
  final data = await ref.read(_noticeRemoteProvider).getUnreadCount(token);
  return data['unreadCount'] as int? ?? 0;
});
