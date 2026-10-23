import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/features/auth/domain/auth_input_validator.dart';

void main() {
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

    test('영문 또는 숫자가 있으면 무효하다', () {
      expect(AuthInputValidator.isNicknameValid('티큐A'), isFalse);
      expect(AuthInputValidator.isNicknameValid('티큐12'), isFalse);
    });

    test('특수문자가 있으면 무효하다', () {
      expect(AuthInputValidator.isNicknameValid('티큐!'), isFalse);
    });

    test('공백이 있으면 무효하다', () {
      expect(AuthInputValidator.isNicknameValid('티 큐'), isFalse);
    });
  });
}
