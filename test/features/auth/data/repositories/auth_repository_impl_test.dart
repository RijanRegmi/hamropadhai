import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hamropadhai/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:hamropadhai/core/services/connectivity/network_info.dart';
import 'package:hamropadhai/features/auth/data/datasources/remote/auth_remote_datasource.dart';
import 'package:hamropadhai/features/auth/data/datasources/local/auth_local_datasource.dart';

class MockNetworkInfo extends Mock implements INetworkInfo {}

class MockRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockLocalDataSource extends Mock implements AuthLocalDatasource {}

void main() {
  late AuthRepository repository;
  late MockNetworkInfo mockNetworkInfo;
  late MockRemoteDataSource mockRemote;
  late MockLocalDataSource mockLocal;

  setUp(() {
    mockNetworkInfo = MockNetworkInfo();
    mockRemote = MockRemoteDataSource();
    mockLocal = MockLocalDataSource();

    repository = AuthRepository(
      networkInfo: mockNetworkInfo,
      remote: mockRemote,
      local: mockLocal,
    );
  });

  test('signup should use remote datasource when online', () async {
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    when(
      () => mockRemote.signup(
        fullName: any(named: 'fullName'),
        username: any(named: 'username'),
        email: any(named: 'email'),
        phone: any(named: 'phone'),
        password: any(named: 'password'),
        gender: any(named: 'gender'),
      ),
    ).thenAnswer((_) async {});

    await repository.signup(
      fullName: 'John',
      username: 'john',
      email: 'john@gmail.com',
      phone: '9800000000',
      password: '123456',
      gender: 'male',
    );

    verify(
      () => mockRemote.signup(
        fullName: any(named: 'fullName'),
        username: any(named: 'username'),
        email: any(named: 'email'),
        phone: any(named: 'phone'),
        password: any(named: 'password'),
        gender: any(named: 'gender'),
      ),
    ).called(1);

    verifyNever(
      () => mockLocal.signup(
        fullName: any(named: 'fullName'),
        username: any(named: 'username'),
        email: any(named: 'email'),
        phone: any(named: 'phone'),
        password: any(named: 'password'),
        gender: any(named: 'gender'),
      ),
    );
  });

  test('signup should use local datasource when offline', () async {
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

    when(
      () => mockLocal.signup(
        fullName: any(named: 'fullName'),
        username: any(named: 'username'),
        email: any(named: 'email'),
        phone: any(named: 'phone'),
        password: any(named: 'password'),
        gender: any(named: 'gender'),
      ),
    ).thenAnswer((_) async {});

    await repository.signup(
      fullName: 'John',
      username: 'john',
      email: 'john@gmail.com',
      phone: '9800000000',
      password: '123456',
      gender: 'male',
    );

    verify(
      () => mockLocal.signup(
        fullName: any(named: 'fullName'),
        username: any(named: 'username'),
        email: any(named: 'email'),
        phone: any(named: 'phone'),
        password: any(named: 'password'),
        gender: any(named: 'gender'),
      ),
    ).called(1);

    verifyNever(
      () => mockRemote.signup(
        fullName: any(named: 'fullName'),
        username: any(named: 'username'),
        email: any(named: 'email'),
        phone: any(named: 'phone'),
        password: any(named: 'password'),
        gender: any(named: 'gender'),
      ),
    );
  });

  test('login should save token locally when online', () async {
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    when(
      () => mockRemote.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => 'token123');

    when(() => mockLocal.saveToken(any())).thenAnswer((_) async {});

    await repository.login(username: 'john', password: '123456');

    verify(
      () => mockRemote.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).called(1);

    verify(() => mockLocal.saveToken('token123')).called(1);
  });
}
