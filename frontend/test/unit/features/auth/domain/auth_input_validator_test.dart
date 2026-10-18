import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/features/auth/domain/auth_input_validator.dart';

void main() {
  group('isPasswordValid', () {
    test('영문과 숫자를 포함한 8자는 유효하다', () {
      expect(AuthInputValidator.isPasswordValid('Abcdef12'), isTrue);
    });

    test('7자는 무효하다', () {
      expect(AuthInputValidator.isPasswordValid('Abcdef1'), isFalse);
    });

    test('64자는 유효하다', () {
      expect(AuthInputValidator.isPasswordValid('A1${'b' * 62}'), isTrue);
    });

    test('65자는 무효하다', () {
      expect(AuthInputValidator.isPasswordValid('A1${'b' * 63}'), isFalse);
    });

    test('숫자가 없으면 무효하다', () {
      expect(AuthInputValidator.isPasswordValid('abcdefgh'), isFalse);
    });

    test('영문이 없으면 무효하다', () {
      expect(AuthInputValidator.isPasswordValid('12345678'), isFalse);
    });

    test('공백이 있으면 무효하다', () {
      expect(AuthInputValidator.isPasswordValid('Abcdef 12'), isFalse);
    });

    test('한글이 있으면 무효하다', () {
      expect(AuthInputValidator.isPasswordValid('Abcdef12가'), isFalse);
    });
  });

  group('isNicknameValid', () {
    test('1자는 무효하다', () {
      expect(AuthInputValidator.isNicknameValid('가'), isFalse);
    });

    test('2자는 유효하다', () {
      expect(AuthInputValidator.isNicknameValid('가나'), isTrue);
    });

    test('10자는 유효하다', () {
      expect(AuthInputValidator.isNicknameValid('가나다라마바사아자차'), isTrue);
    });

    test('11자는 무효하다', () {
      expect(AuthInputValidator.isNicknameValid('가나다라마바사아자차카'), isFalse);
    });

    test('특수문자가 있으면 무효하다', () {
      expect(AuthInputValidator.isNicknameValid('티큐!'), isFalse);
    });

    test('공백이 있으면 무효하다', () {
      expect(AuthInputValidator.isNicknameValid('티 큐'), isFalse);
    });
  });

  group('isEmailFormatValid', () {
    test('단순 형식을 만족하면 유효하다', () {
      expect(AuthInputValidator.isEmailFormatValid('a@b.co'), isTrue);
    });

    test('254자는 유효하다', () {
      final email = '${'a' * 248}@b.com';
      expect(email.length, 254);
      expect(AuthInputValidator.isEmailFormatValid(email), isTrue);
    });

    test('255자는 무효하다', () {
      final email = '${'a' * 249}@b.com';
      expect(email.length, 255);
      expect(AuthInputValidator.isEmailFormatValid(email), isFalse);
    });

    for (final invalid in ['a@b', '@b.co', 'a b@c.co', 'a@b.', ' a@b.co ']) {
      test('"$invalid"는 무효하다', () {
        expect(AuthInputValidator.isEmailFormatValid(invalid), isFalse);
      });
    }
  });
}
