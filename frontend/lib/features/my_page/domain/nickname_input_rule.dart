import 'package:teeq/features/auth/domain/auth_input_validator.dart';

/// 닉네임 입력값이 규칙을 어긴 이유.
enum NicknameInputIssue { invalidCharacter, tooShort, tooLong }

/// 닉네임 변경 입력 규칙. 최종 유효성은 [AuthInputValidator]가 판정하고,
/// 이 클래스는 위반 이유 분류와 제출 가능 여부만 다룬다.
/// 입력은 trim하지 않는다(공백은 허용되지 않는 문자다).
abstract final class NicknameInputRule {
  static const int minLength = 2;
  static const int maxLength = 10;

  static final RegExp _disallowedCharacterPattern = RegExp(r'[^가-힣]');

  /// 빈 문자열이거나 위반이 없으면 null.
  static NicknameInputIssue? issueOf(String input) {
    if (input.isEmpty) {
      return null;
    }
    if (_disallowedCharacterPattern.hasMatch(input)) {
      return NicknameInputIssue.invalidCharacter;
    }
    if (input.length < minLength) {
      return NicknameInputIssue.tooShort;
    }
    if (input.length > maxLength) {
      return NicknameInputIssue.tooLong;
    }
    return null;
  }

  /// 대소문자를 구분한 정확한 비교로 현재 닉네임과 다를 때만 제출할 수 있다.
  static bool isSubmittable(String input, String currentNickname) =>
      input.isNotEmpty &&
      AuthInputValidator.isNicknameValid(input) &&
      input != currentNickname;
}
