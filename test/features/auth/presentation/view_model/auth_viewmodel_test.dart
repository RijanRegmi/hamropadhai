import 'package:flutter_test/flutter_test.dart';

class AuthValidation {
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^9[0-9]{9}$');
    return phoneRegex.hasMatch(phone);
  }

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  static bool isValidUsername(String username) {
    return username.length >= 3 &&
        RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username);
  }

  static bool isValidName(String name) {
    return name.trim().length >= 2;
  }

  static bool passwordsMatch(String password, String confirmPassword) {
    return password == confirmPassword;
  }
}

void main() {
  group('Auth Validation Unit Tests', () {
    test('1. Should validate correct email format', () {
      const validEmail = 'john@example.com';
      const invalidEmail1 = 'johnexample.com';
      const invalidEmail2 = 'john@';
      const invalidEmail3 = '@example.com';

      expect(AuthValidation.isValidEmail(validEmail), true);
      expect(AuthValidation.isValidEmail(invalidEmail1), false);
      expect(AuthValidation.isValidEmail(invalidEmail2), false);
      expect(AuthValidation.isValidEmail(invalidEmail3), false);
    });

    test('2. Should validate Nepal phone number format', () {
      const validPhone = '9812345678';
      const invalidPhone1 = '1234567890';
      const invalidPhone2 = '98123456';
      const invalidPhone3 = '98123456789';
      const invalidPhone4 = '981234567a';

      expect(AuthValidation.isValidPhone(validPhone), true);
      expect(AuthValidation.isValidPhone(invalidPhone1), false);
      expect(AuthValidation.isValidPhone(invalidPhone2), false);
      expect(AuthValidation.isValidPhone(invalidPhone3), false);
      expect(AuthValidation.isValidPhone(invalidPhone4), false);
    });

    test('3. Should validate password length', () {
      const validPassword = 'password123';
      const shortPassword = '12345';
      const emptyPassword = '';

      expect(AuthValidation.isValidPassword(validPassword), true);
      expect(AuthValidation.isValidPassword(shortPassword), false);
      expect(AuthValidation.isValidPassword(emptyPassword), false);
    });

    test('4. Should validate username format', () {
      const validUsername1 = 'johndoe';
      const validUsername2 = 'john_doe123';
      const invalidUsername1 = 'jo';
      const invalidUsername2 = 'john doe';
      const invalidUsername3 = 'john@doe';
      const invalidUsername4 = '';

      expect(AuthValidation.isValidUsername(validUsername1), true);
      expect(AuthValidation.isValidUsername(validUsername2), true);
      expect(AuthValidation.isValidUsername(invalidUsername1), false);
      expect(AuthValidation.isValidUsername(invalidUsername2), false);
      expect(AuthValidation.isValidUsername(invalidUsername3), false);
      expect(AuthValidation.isValidUsername(invalidUsername4), false);
    });

    test('5. Should check if passwords match', () {
      const password = 'password123';
      const matchingPassword = 'password123';
      const nonMatchingPassword = 'password456';

      expect(AuthValidation.passwordsMatch(password, matchingPassword), true);
      expect(
        AuthValidation.passwordsMatch(password, nonMatchingPassword),
        false,
      );
    });
  });

  group('Additional Validation Tests', () {
    test('6. Should validate name format', () {
      const validName = 'John Doe';
      const shortName = 'J';
      const emptyName = '';
      const spacesName = '   ';

      expect(AuthValidation.isValidName(validName), true);
      expect(AuthValidation.isValidName(shortName), false);
      expect(AuthValidation.isValidName(emptyName), false);
      expect(AuthValidation.isValidName(spacesName), false);
    });
  });
}
