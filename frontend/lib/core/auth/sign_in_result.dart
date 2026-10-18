import 'package:teeq/core/auth/auth_tokens.dart';
import 'package:teeq/core/auth/member.dart';

/// 로그인 성공 결과: 발급된 토큰과 회원.
final class SignInResult {
  const SignInResult({required this.tokens, required this.member});

  final AuthTokens tokens;
  final Member member;
}
