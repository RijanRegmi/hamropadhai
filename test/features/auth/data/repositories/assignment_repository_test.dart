import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hamropadhai/features/auth/data/repositories/assignment_repository.dart';
import 'package:hamropadhai/features/auth/data/datasources/remote/assignment_remote_datasource.dart';
import 'package:hamropadhai/features/auth/data/datasources/local/auth_local_datasource.dart';

class MockAssignmentRemote extends Mock implements AssignmentRemoteDatasource {}

class MockLocalDataSource extends Mock implements AuthLocalDatasource {}

void main() {
  late AssignmentRepository repository;
  late MockAssignmentRemote mockRemote;
  late MockLocalDataSource mockLocal;

  setUp(() {
    mockRemote = MockAssignmentRemote();
    mockLocal = MockLocalDataSource();
    repository = AssignmentRepository(remote: mockRemote, local: mockLocal);
  });

  test('1. getMyAssignments returns list when token exists', () async {
    when(() => mockLocal.getToken()).thenAnswer((_) async => 'token123');
    when(() => mockRemote.getMyAssignments(any())).thenAnswer(
      (_) async => [
        {'_id': 'a1', 'title': 'Math HW'},
        {'_id': 'a2', 'title': 'Science HW'},
      ],
    );

    final result = await repository.getMyAssignments();

    expect(result, isA<List<Map<String, dynamic>>>());
    expect(result.length, 2);
    expect(result.first['title'], 'Math HW');
  });

  test('2. getMyAssignments throws exception when not logged in', () async {
    when(() => mockLocal.getToken()).thenAnswer((_) async => null);

    expect(() => repository.getMyAssignments(), throwsException);
    verifyNever(() => mockRemote.getMyAssignments(any()));
  });

  test('3. getMyAssignments calls remote with correct token', () async {
    when(() => mockLocal.getToken()).thenAnswer((_) async => 'my_token');
    when(() => mockRemote.getMyAssignments(any())).thenAnswer((_) async => []);

    await repository.getMyAssignments();

    verify(() => mockRemote.getMyAssignments('my_token')).called(1);
  });

  test('4. getMyAssignments returns empty list when no assignments', () async {
    when(() => mockLocal.getToken()).thenAnswer((_) async => 'token123');
    when(() => mockRemote.getMyAssignments(any())).thenAnswer((_) async => []);

    final result = await repository.getMyAssignments();

    expect(result, isEmpty);
  });

  test('5. getMyAssignments throws when remote throws', () async {
    when(() => mockLocal.getToken()).thenAnswer((_) async => 'token123');
    when(
      () => mockRemote.getMyAssignments(any()),
    ).thenThrow(Exception('Server error'));

    expect(() => repository.getMyAssignments(), throwsException);
  });
}
