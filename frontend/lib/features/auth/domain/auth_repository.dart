import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/auth/sign_in_result.dart';
import 'package:teeq/features/auth/domain/profile_image_file.dart';

/// 인증·회원 API 계약.
abstract interface class AuthRepository {
  /// Firebase ID token으로 로그인한다. 가입하지 않은 회원이면 서버가 `AUTH_SIGNUP_REQUIRED`로 응답한다.
  Future<SignInResult> login({required String credential});

  /// Firebase ID token과 약관 동의·닉네임으로 가입하고 로그인한다.
  Future<SignInResult> signUp({
    required String credential,
    required String nickname,
    required bool serviceTermsAgreed,
    required bool privacyPolicyAgreed,
  });

  /// 닉네임을 아직 아무도 쓰지 않는지 확인한다(로그인 전에도 호출할 수 있는 공개 API).
  Future<bool> checkNicknameAvailability({required String nickname});

  Future<void> logout();

  Future<Member> fetchMe();

  /// 회원 탈퇴. 성공하면 서버가 토큰을 폐기한다.
  Future<void> deleteAccount();

  /// 닉네임을 바꾸고 갱신된 회원을 돌려준다.
  Future<Member> changeNickname({required String nickname});

  /// 프로필 사진을 교체하고 갱신된 회원을 돌려준다.
  Future<Member> replaceProfileImage(ProfileImageFile image);
}
