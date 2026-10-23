import 'package:teeq/features/auth/domain/auth_input_validator.dart';

/// 새 비밀번호가 규칙을 어긴 이유와 화면에 보여 줄 문구.
enum NewPasswordIssue {
  invalidCharacter('공백과 한글은 사용할 수 없어'),
  tooShort('비밀번호는 8자 이상으로 입력해줘'),
  tooLong('비밀번호는 64자 이하로 입력해줘'),
  missingLetterOrDigit('영문과 숫자를 함께 입력해줘');

  const NewPasswordIssue(this.message);

  final String message;
}

/// 비밀번호 변경 입력 규칙. 최종 유효성은 [AuthInputValidator]가 판정한다.
abstract final class PasswordChangeInputRule {
  static const int minLength = 8;
  static const int maxLength = 64;

  static final RegExp _disallowedCharacterPattern = RegExp(r'[^\x21-\x7E]');

  /// 빈 값이거나 위반이 없으면 null.
  static NewPasswordIssue? newPasswordIssueOf(String newPassword) {
    if (newPassword.isEmpty) {
      return null;
    }
    if (_disallowedCharacterPattern.hasMatch(newPassword)) {
      return NewPasswordIssue.invalidCharacter;
    }
    if (newPassword.length < minLength) {
      return NewPasswordIssue.tooShort;
    }
    if (newPassword.length > maxLength) {
      return NewPasswordIssue.tooLong;
    }
    if (!AuthInputValidator.isPasswordValid(newPassword)) {
      return NewPasswordIssue.missingLetterOrDigit;
    }
    return null;
  }

  /// 확인 입력이 비어 있으면 불일치로 보지 않는다.
  static bool isConfirmationMismatch(String newPassword, String confirmation) =>
      confirmation.isNotEmpty && newPassword != confirmation;

  /// 새 비밀번호가 현재와 같아도 허용한다(BE도 검사하지 않는다).
  static bool canSubmit({
    required String current,
    required String next,
    required String confirmation,
  }) =>
      current.isNotEmpty &&
      next.isNotEmpty &&
      confirmation.isNotEmpty &&
      AuthInputValidator.isPasswordValid(next) &&
      next == confirmation;
}
