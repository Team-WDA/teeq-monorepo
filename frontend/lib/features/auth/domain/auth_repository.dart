import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/auth/sign_in_result.dart';

/// 인증·회원 API 계약.
abstract interface class AuthRepository {
  Future<SignInResult> login({required String email, required String password});

  Future<SignInResult> signUp({
    required String email,
    required String password,
    required String nickname,
    required bool serviceTermsAgreed,
    required bool privacyPolicyAgreed,
  });

  /// Apple identity token으로 로그인한다. 첫 로그인이면 서버가 회원을 만든다.
  Future<SignInResult> socialLogin({required String credential});

  Future<void> logout();

  Future<Member> fetchMe();

  /// 회원 탈퇴. 성공하면 서버가 토큰을 폐기한다.
  Future<void> deleteAccount();

  /// 닉네임 없이 시작한 회원의 가입을 완료한다.
  Future<Member> completeSignup({
    required String nickname,
    required bool serviceTermsAgreed,
    required bool privacyPolicyAgreed,
  });
}
