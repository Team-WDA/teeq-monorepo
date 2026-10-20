import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/features/my_page/domain/password_change_input_rule.dart';

void main() {
  group('PasswordChangeInputRule.newPasswordIssueOf', () {
    test('빈 값은 이슈가 없다', () {
      expect(PasswordChangeInputRule.newPasswordIssueOf(''), isNull);
    });

    test('7자는 tooShort, 8자는 유효하다', () {
      expect(
        PasswordChangeInputRule.newPasswordIssueOf('abcde12'),
        NewPasswordIssue.tooShort,
      );
      expect(PasswordChangeInputRule.newPasswordIssueOf('abcdef12'), isNull);
    });

    test('영문만 또는 숫자만이면 missingLetterOrDigit', () {
      expect(
        PasswordChangeInputRule.newPasswordIssueOf('abcdefgh'),
        NewPasswordIssue.missingLetterOrDigit,
      );
      expect(
        PasswordChangeInputRule.newPasswordIssueOf('12345678'),
        NewPasswordIssue.missingLetterOrDigit,
      );
    });

    test('공백이 있으면 invalidCharacter', () {
      expect(
        PasswordChangeInputRule.newPasswordIssueOf('abcd 1234'),
        NewPasswordIssue.invalidCharacter,
      );
    });

    test('한글이 있으면 invalidCharacter', () {
      expect(
        PasswordChangeInputRule.newPasswordIssueOf('abcd1234가'),
        NewPasswordIssue.invalidCharacter,
      );
    });

    test('허용 문자 위반이 길이 위반보다 우선한다', () {
      expect(
        PasswordChangeInputRule.newPasswordIssueOf('a1 '),
        NewPasswordIssue.invalidCharacter,
      );
    });

    test('64자는 유효하고 65자는 tooLong', () {
      final sixtyFour = 'a1${'b' * 62}';
      expect(PasswordChangeInputRule.newPasswordIssueOf(sixtyFour), isNull);
      expect(
        PasswordChangeInputRule.newPasswordIssueOf('${sixtyFour}b'),
        NewPasswordIssue.tooLong,
      );
    });

    test('특수문자는 허용된다', () {
      expect(PasswordChangeInputRule.newPasswordIssueOf('abc123!@#'), isNull);
    });

    test('문구가 시안과 계획대로다', () {
      expect(NewPasswordIssue.tooShort.message, '비밀번호는 8자 이상으로 입력해줘');
      expect(NewPasswordIssue.missingLetterOrDigit.message, '영문과 숫자를 함께 입력해줘');
      expect(NewPasswordIssue.tooLong.message, '비밀번호는 64자 이하로 입력해줘');
      expect(NewPasswordIssue.invalidCharacter.message, '공백과 한글은 사용할 수 없어');
    });
  });

  group('PasswordChangeInputRule.isConfirmationMismatch', () {
    test('확인이 비어 있으면 불일치가 아니다', () {
      expect(
        PasswordChangeInputRule.isConfirmationMismatch('abcd1234', ''),
        isFalse,
      );
    });

    test('다르면 불일치', () {
      expect(
        PasswordChangeInputRule.isConfirmationMismatch('abcd1234', 'abcd123'),
        isTrue,
      );
    });

    test('같으면 불일치가 아니다', () {
      expect(
        PasswordChangeInputRule.isConfirmationMismatch('abcd1234', 'abcd1234'),
        isFalse,
      );
    });
  });

  group('PasswordChangeInputRule.canSubmit', () {
    bool canSubmit(String current, String next, String confirmation) =>
        PasswordChangeInputRule.canSubmit(
          current: current,
          next: next,
          confirmation: confirmation,
        );

    test('모두 채우고 유효하며 일치하면 true', () {
      expect(canSubmit('old', 'abcd1234', 'abcd1234'), isTrue);
    });

    test('하나라도 비어 있으면 false', () {
      expect(canSubmit('', 'abcd1234', 'abcd1234'), isFalse);
      expect(canSubmit('old', '', 'abcd1234'), isFalse);
      expect(canSubmit('old', 'abcd1234', ''), isFalse);
    });

    test('새 비밀번호가 유효하지 않으면 false', () {
      expect(canSubmit('old', 'abcdefgh', 'abcdefgh'), isFalse);
      expect(canSubmit('old', 'abc12', 'abc12'), isFalse);
    });

    test('확인이 다르면 false', () {
      expect(canSubmit('old', 'abcd1234', 'abcd1235'), isFalse);
    });

    test('새 비밀번호가 현재와 같아도 허용한다', () {
      expect(canSubmit('abcd1234', 'abcd1234', 'abcd1234'), isTrue);
    });
  });
}
