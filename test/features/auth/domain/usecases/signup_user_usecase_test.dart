import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hamropadhai/features/auth/domain/usecases/signup_user_usecase.dart';
import 'package:hamropadhai/features/auth/domain/repositories/auth_repository.dart';
import 'package:hamropadhai/features/auth/domain/entities/user_entity.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeUserEntity extends Fake implements UserEntity {}

void main() {
  late SignupUserUsecase usecase;
  late MockAuthRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeUserEntity());
  });

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = SignupUserUsecase(mockRepository);
  });

  test('Should call repository.signup()', () async {
    final user = UserEntity(
      userId: '1',
      name: 'John Doe',
      email: 'john@gmail.com',
      phone: '9800000000',
      password: '123456',
    );

    when(() => mockRepository.signup(any())).thenAnswer((_) async {});

    await usecase(user);

    verify(() => mockRepository.signup(user)).called(1);
  });
}
