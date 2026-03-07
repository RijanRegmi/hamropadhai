import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hamropadhai/core/api/api_client.dart';
import 'package:hamropadhai/core/api/api_endpoints.dart';
import 'package:hamropadhai/features/auth/data/datasources/remote/auth_remote_datasource.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late AuthRemoteDataSourceImpl datasource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    datasource = AuthRemoteDataSourceImpl(mockApiClient);
  });

  test('signup should call ApiClient.post with correct data', () async {
    when(
      () => mockApiClient.post(any(), body: any(named: 'body')),
    ).thenAnswer((_) async => {});

    await datasource.signup(
      fullName: 'John Doe',
      username: 'john',
      email: 'john@gmail.com',
      phone: '9800000000',
      password: '123456',
      gender: 'male',
    );

    verify(
      () => mockApiClient.post(
        ApiEndpoints.baseUrl + ApiEndpoints.signup,
        body: {
          "fullName": "John Doe",
          "username": "john",
          "email": "john@gmail.com",
          "phone": "9800000000",
          "password": "123456",
          "gender": "male",
        },
      ),
    ).called(1);
  });

  test('login should return token when response is valid', () async {
    when(() => mockApiClient.post(any(), body: any(named: 'body'))).thenAnswer(
      (_) async => {
        "success": true,
        "data": {"token": "test_token"},
      },
    );

    final token = await datasource.login(username: 'john', password: '123456');

    expect(token, 'test_token');
    verify(
      () => mockApiClient.post(
        ApiEndpoints.baseUrl + ApiEndpoints.login,
        body: {"username": "john", "password": "123456"},
      ),
    ).called(1);
  });

  test('login should throw exception when success is false', () async {
    when(
      () => mockApiClient.post(any(), body: any(named: 'body')),
    ).thenAnswer((_) async => {"success": false, "message": "Bad credentials"});

    expect(
      () => datasource.login(username: 'john', password: 'wrong'),
      throwsException,
    );
  });

  test('login should throw when token is missing from response data', () async {
    when(
      () => mockApiClient.post(any(), body: any(named: 'body')),
    ).thenAnswer((_) async => {"success": true, "data": {}});

    expect(
      () => datasource.login(username: 'john', password: '123456'),
      throwsException,
    );
  });

  test('getProfile should call correct endpoint with Bearer token', () async {
    when(
      () => mockApiClient.get(any(), headers: any(named: 'headers')),
    ).thenAnswer(
      (_) async => {
        "data": {"fullName": "John Doe", "email": "john@gmail.com"},
      },
    );

    final result = await datasource.getProfile('test_token');

    expect(result['fullName'], 'John Doe');
    verify(
      () => mockApiClient.get(
        ApiEndpoints.baseUrl + ApiEndpoints.profile,
        headers: {'Authorization': 'Bearer test_token'},
      ),
    ).called(1);
  });

  test(
    'updateProfile should return updated data when success is true',
    () async {
      when(
        () => mockApiClient.put(
          any(),
          body: any(named: 'body'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => {
          "success": true,
          "data": {"fullName": "Updated Name"},
        },
      );

      final result = await datasource.updateProfile('test_token', {
        'fullName': 'Updated Name',
      });

      expect(result['fullName'], 'Updated Name');
    },
  );

  test('updateProfile should throw exception when success is false', () async {
    when(
      () => mockApiClient.put(
        any(),
        body: any(named: 'body'),
        headers: any(named: 'headers'),
      ),
    ).thenAnswer((_) async => {"success": false, "message": "Update failed"});

    expect(
      () => datasource.updateProfile('test_token', {'fullName': 'X'}),
      throwsException,
    );
  });
}
