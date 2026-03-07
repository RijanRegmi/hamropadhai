import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hamropadhai/features/auth/data/repositories/notice_repository.dart';
import 'package:hamropadhai/features/auth/data/datasources/remote/notice_remote_datasource.dart';

class MockNoticeRemote extends Mock implements NoticeRemoteDatasource {}

void main() {
  late NoticeRepository repository;
  late MockNoticeRemote mockRemote;

  const token = 'test_token';

  setUp(() {
    mockRemote = MockNoticeRemote();
    repository = NoticeRepository(mockRemote);
  });

  test('1. getMyNotices returns list of notices on success', () async {
    when(() => mockRemote.getMyNotices(any())).thenAnswer(
      (_) async => [
        {'_id': 'n1', 'title': 'Holiday Notice'},
        {'_id': 'n2', 'title': 'Exam Schedule'},
      ],
    );

    final result = await repository.getMyNotices(token);

    expect(result, isA<List<Map<String, dynamic>>>());
    expect(result.length, 2);
    expect(result.first['title'], 'Holiday Notice');
    verify(() => mockRemote.getMyNotices(token)).called(1);
  });

  test('2. getMyNotices throws when remote throws', () async {
    when(
      () => mockRemote.getMyNotices(any()),
    ).thenThrow(Exception('Unauthorized'));

    expect(() => repository.getMyNotices(token), throwsException);
  });

  test('3. getUnreadCount returns correct count', () async {
    when(() => mockRemote.getUnreadCount(any())).thenAnswer((_) async => 5);

    final result = await repository.getUnreadCount(token);

    expect(result, 5);
    verify(() => mockRemote.getUnreadCount(token)).called(1);
  });

  test('4. getUnreadCount returns zero when no unread notices', () async {
    when(() => mockRemote.getUnreadCount(any())).thenAnswer((_) async => 0);

    final result = await repository.getUnreadCount(token);

    expect(result, 0);
  });

  test('5. getPinnedNotices returns pinned notices', () async {
    when(() => mockRemote.getPinnedNotices(any())).thenAnswer(
      (_) async => [
        {'_id': 'n3', 'title': 'Pinned Notice', 'isPinned': true},
      ],
    );

    final result = await repository.getPinnedNotices(token);

    expect(result.first['isPinned'], true);
    verify(() => mockRemote.getPinnedNotices(token)).called(1);
  });

  test('6. getPinnedNotices throws when remote throws', () async {
    when(
      () => mockRemote.getPinnedNotices(any()),
    ).thenThrow(Exception('Failed to fetch'));

    expect(() => repository.getPinnedNotices(token), throwsException);
  });

  test('7. getNoticeById returns correct notice', () async {
    when(
      () => mockRemote.getNoticeById(any(), any()),
    ).thenAnswer((_) async => {'_id': 'n1', 'title': 'Holiday Notice'});

    final result = await repository.getNoticeById(token, 'n1');

    expect(result['_id'], 'n1');
    expect(result['title'], 'Holiday Notice');
    verify(() => mockRemote.getNoticeById(token, 'n1')).called(1);
  });

  test('8. getNoticeById throws when notice not found', () async {
    when(
      () => mockRemote.getNoticeById(any(), any()),
    ).thenThrow(Exception('Notice not found'));

    expect(
      () => repository.getNoticeById(token, 'invalid_id'),
      throwsException,
    );
  });

  test('9. markAsRead calls remote with correct token and noticeId', () async {
    when(() => mockRemote.markAsRead(any(), any())).thenAnswer((_) async {});

    await repository.markAsRead(token, 'n1');

    verify(() => mockRemote.markAsRead(token, 'n1')).called(1);
  });

  test('10. markAsRead throws when remote throws', () async {
    when(
      () => mockRemote.markAsRead(any(), any()),
    ).thenThrow(Exception('Failed to mark as read'));

    expect(() => repository.markAsRead(token, 'n1'), throwsException);
  });
}
