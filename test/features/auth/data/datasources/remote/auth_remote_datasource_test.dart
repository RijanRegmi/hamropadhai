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
}
