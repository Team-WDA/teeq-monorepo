import 'package:teeq/core/auth/login_type.dart';

/// 서버의 로그인 방식 문자열을 [LoginType]으로 바꾼다. 모르는 값은 매핑 오류로 던진다.
LoginType loginTypeFromJson(String value) => switch (value) {
  'APPLE' => LoginType.apple,
  'GOOGLE' => LoginType.google,
  'EMAIL' => LoginType.email,
  _ => throw FormatException('알 수 없는 로그인 방식: $value'),
};
