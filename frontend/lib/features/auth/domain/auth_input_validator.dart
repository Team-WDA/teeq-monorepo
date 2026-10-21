/// 가입·로그인 입력값 형식 검증. 비밀번호·닉네임 규칙은 BE `MemberValidation`과 같다.
/// 앞뒤 공백은 호출부가 `trim()`한 값을 넘긴다.
abstract final class AuthInputValidator {
  /// BE `SignUpRequest`의 이메일 최대 길이.
  static const int _emailMaxLength = 254;

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final RegExp _passwordPattern = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)[\x21-\x7E]{8,64}$',
  );
  static final RegExp _nicknamePattern = RegExp(r'^[가-힣]{2,10}$');

  static bool isEmailFormatValid(String value) =>
      value.length <= _emailMaxLength && _emailPattern.hasMatch(value);

  static bool isPasswordValid(String value) => _passwordPattern.hasMatch(value);

  static bool isNicknameValid(String value) => _nicknamePattern.hasMatch(value);
}
