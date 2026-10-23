/// 닉네임 형식 검증. 규칙은 BE `MemberValidation`과 같다.
/// 앞뒤 공백은 호출부가 `trim()`한 값을 넘긴다.
abstract final class AuthInputValidator {
  static final RegExp _nicknamePattern = RegExp(r'^[가-힣]{2,10}$');

  static bool isNicknameValid(String value) => _nicknamePattern.hasMatch(value);
}
