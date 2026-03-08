import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:hamropadhai/core/api/api_endpoints.dart';
import 'package:hamropadhai/features/auth/data/datasources/remote/assignment_remote_datasource.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late AssignmentRemoteDatasource datasource;
  late MockHttpClient mockClient;

  const token = 'test_token';

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await ApiEndpoints.init();
    registerFallbackValue(Uri.parse('http://fallback.test'));
  });

  setUp(() {
    mockClient = MockHttpClient();
    datasource = AssignmentRemoteDatasource(mockClient);
  });

  http.Response okResponse(dynamic data) => http.Response(
    jsonEncode({'data': data}),
    200,
    headers: {'content-type': 'application/json'},
  );

  http.Response errorResponse(String message, [int code = 400]) =>
      http.Response(
        jsonEncode({'message': message}),
        code,
        headers: {'content-type': 'application/json'},
      );

  group('getMyAssignments', () {
    test('1. Should return list of assignments on success', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => okResponse([
          {'_id': '1', 'title': 'Math HW'},
        ]),
      );

      final result = await datasource.getMyAssignments(token);

      expect(result, isA<List<Map<String, dynamic>>>());
      expect(result.first['title'], 'Math HW');
    });

    test('2. Should throw Exception when server returns error', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => errorResponse('Unauthorized', 401));

      expect(() => datasource.getMyAssignments(token), throwsException);
    });
  });

  group('getPendingAssignments', () {
    test('3. Should return pending assignments on success', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => okResponse([
          {'_id': '2', 'title': 'Pending Science'},
        ]),
      );

      final result = await datasource.getPendingAssignments(token);

      expect(result.first['title'], 'Pending Science');
    });

    test('4. Should throw Exception on failure', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => errorResponse('Failed to fetch pending assignments'),
      );

      expect(() => datasource.getPendingAssignments(token), throwsException);
    });
  });

  group('getSubmittedAssignments', () {
    test('5. Should return submitted assignments on success', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => okResponse([
          {'_id': '3', 'title': 'Submitted English'},
        ]),
      );

      final result = await datasource.getSubmittedAssignments(token);

      expect(result.first['title'], 'Submitted English');
    });

    test('6. Should throw Exception on failure', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => errorResponse('Failed to fetch submitted assignments'),
      );

      expect(() => datasource.getSubmittedAssignments(token), throwsException);
    });
  });

  group('getGradedAssignments', () {
    test('7. Should return graded assignments', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => okResponse([
          {'_id': '4', 'title': 'Graded Physics', 'marks': 18},
        ]),
      );

      final result = await datasource.getGradedAssignments(token);

      expect(result.first['marks'], 18);
    });

    test('8. Should throw Exception on failure', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => errorResponse('Failed to fetch graded assignments'),
      );

      expect(() => datasource.getGradedAssignments(token), throwsException);
    });
  });

  group('submitAssignment', () {
    test('9. Should return submission data on success', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => okResponse({'submittedAt': '2024-01-01'}));

      final result = await datasource.submitAssignment(
        token,
        'assign1',
        'My answer',
      );

      expect(result, isA<Map<String, dynamic>>());
    });

    test('10. Should throw Exception when submit fails', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => errorResponse('Failed to submit assignment'));

      expect(
        () => datasource.submitAssignment(token, 'assign1', 'answer'),
        throwsException,
      );
    });
  });
}
