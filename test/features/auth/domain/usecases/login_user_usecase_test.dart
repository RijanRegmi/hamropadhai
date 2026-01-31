import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hamropadhai/features/auth/domain/usecases/login_user_usecase.dart';
import 'package:hamropadhai/features/auth/domain/repositories/auth_repository.dart';
import 'package:hamropadhai/features/auth/domain/entities/user_entity.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeUserEntity extends Fake implements UserEntity {}

void main() {
  late LoginUserUsecase usecase;
  late MockAuthRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeUserEntity());
  });

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = LoginUserUsecase(mockRepository);
  });

  test('Should return UserEntity when login is successful', () async {
    final user = UserEntity(
      userId: '1',
      name: 'John Doe',
      email: 'john@gmail.com',
      phone: '9800000000',
      password: '123456',
    );

    when(
      () => mockRepository.login('john@gmail.com', '123456'),
    ).thenAnswer((_) async => user);

    final result = await usecase('john@gmail.com', '123456');

    expect(result, user);
    verify(() => mockRepository.login('john@gmail.com', '123456')).called(1);
  });
}
