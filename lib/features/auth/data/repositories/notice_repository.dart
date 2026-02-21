import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:hamropadhai/features/auth/data/datasources/remote/notice_remote_datasource.dart';

final noticeRepositoryProvider = Provider<NoticeRepository>(
  (ref) => NoticeRepository(NoticeRemoteDatasource(http.Client())),
);

class NoticeRepository {
  final NoticeRemoteDatasource _remote;

  NoticeRepository(this._remote);

  Future<List<Map<String, dynamic>>> getMyNotices(String token) =>
      _remote.getMyNotices(token);

  Future<int> getUnreadCount(String token) => _remote.getUnreadCount(token);

  Future<List<Map<String, dynamic>>> getPinnedNotices(String token) =>
      _remote.getPinnedNotices(token);

  Future<Map<String, dynamic>> getNoticeById(String token, String noticeId) =>
      _remote.getNoticeById(token, noticeId);

  Future<void> markAsRead(String token, String noticeId) =>
      _remote.markAsRead(token, noticeId);
}
