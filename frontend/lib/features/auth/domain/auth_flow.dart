import 'package:teeq/core/auth/auth_session.dart';
import 'package:teeq/core/auth/auth_status.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/auth/sign_in_result.dart';
import 'package:teeq/core/auth/token_storage.dart';
import 'package:teeq/features/auth/domain/auth_repository.dart';
import 'package:teeq/features/auth/domain/profile_image_file.dart';
import 'package:teeq/features/auth/domain/social_credential_provider.dart';

/// 소셜 로그인 시도의 결과. 취소와 가입 필요는 오류가 아니라 화면이 분기할 결과다.
enum SocialSignInOutcome {
  /// 가입된 회원으로 로그인했다.
  signedIn,

  /// 사용자가 로그인을 취소했다. 상태를 바꾸지 않는다.
  cancelled,

  /// 아직 가입하지 않은 계정이다. 약관·닉네임 단계로 이어가야 한다.
  signupRequired,
}

/// 화면이 부르는 인증 흐름(복원, 로그인, 가입, 로그아웃)을 한곳에 모은다.
/// 협력자를 생성자로 받아 dio와 Riverpod을 모른 채 단위 테스트할 수 있다.
class AuthFlow {
  AuthFlow({
    required this._repository,
    required this._socialCredentialProvider,
    required this._session,
    required this._tokenStorage,
    required this._readStatus,
    required this._reportError,
    required this._isSignupRequired,
    required this._isStateConflict,
  });

  final AuthRepository _repository;
  final SocialCredentialProvider _socialCredentialProvider;
  final AuthSession _session;
  final TokenStorage _tokenStorage;
  final AuthStatus Function() _readStatus;
  final void Function(Object error, {bool blocking}) _reportError;

  /// 소셜 로그인 오류가 "가입이 필요한 계정(SOCIAL_SIGNUP_REQUIRED)"인지 판정한다.
  /// 오류 객체를 해석하려면 dio에 의존해야 하므로 domain 밖에서 주입한다.
  final bool Function(Object error) _isSignupRequired;

  /// 소셜 가입 오류가 "서버는 이미 가입이 끝났다(STATE_CONFLICT)"인지 판정한다.
  final bool Function(Object error) _isStateConflict;

  /// 앱 시작 시 저장된 토큰으로 로그인 상태를 복원한다. 이미 복원된 뒤에는 아무것도 하지 않는다.
  /// 실패하면 상태와 토큰을 그대로 두고 오류만 알린다(오프라인 시작이 토큰을 지우면 안 된다).
  Future<void> restore() async {
    if (_readStatus() != AuthStatus.unknown) {
      return;
    }
    try {
      final tokens = await _tokenStorage.read();
      if (tokens == null) {
        await _session.signOut();
        return;
      }
      final member = await _repository.fetchMe();
      await _session.restored(member);
    } on Exception catch (error) {
      _reportError(error, blocking: true);
    }
  }

  /// Apple로 로그인한다.
  Future<SocialSignInOutcome> signInWithApple() =>
      _signInWith(_socialCredentialProvider.signInWithApple);

  /// Google로 로그인한다.
  Future<SocialSignInOutcome> signInWithGoogle() =>
      _signInWith(_socialCredentialProvider.signInWithGoogle);

  Future<SocialSignInOutcome> _signInWith(
    Future<String> Function() requestCredential,
  ) async {
    final String credential;
    try {
      credential = await requestCredential();
    } on SocialSignInCancelledException {
      return SocialSignInOutcome.cancelled;
    }
    final SignInResult result;
    try {
      result = await _repository.socialLogin(credential: credential);
    } on Object catch (error) {
      if (_isSignupRequired(error)) {
        return SocialSignInOutcome.signupRequired;
      }
      rethrow;
    }
    await _session.signIn(result);
    return SocialSignInOutcome.signedIn;
  }

  /// 약관 동의와 닉네임으로 소셜 가입을 마치고 로그인한다. 최신 Firebase ID token을 다시 받아 쓴다.
  /// 서버가 이미 가입을 마친 상태(STATE_CONFLICT)라면 같은 token으로 로그인을 한 번 다시 시도한다.
  /// 그 밖의 오류(중복 닉네임 등)는 그대로 던진다.
  Future<void> completeSocialSignup({
    required String nickname,
    required bool serviceTermsAgreed,
    required bool privacyPolicyAgreed,
  }) async {
    final credential = await _socialCredentialProvider.fetchLatestIdToken();
    final SignInResult result;
    try {
      result = await _repository.socialSignUp(
        credential: credential,
        nickname: nickname,
        serviceTermsAgreed: serviceTermsAgreed,
        privacyPolicyAgreed: privacyPolicyAgreed,
      );
    } on Object catch (error) {
      if (!_isStateConflict(error)) {
        rethrow;
      }
      await _session.signIn(
        await _repository.socialLogin(credential: credential),
      );
      return;
    }
    await _session.signIn(result);
  }

  /// 서버에서 최신 회원 정보를 받아 보관 중인 회원을 갱신한다(로그인 응답에 없는 이메일 등).
  /// 응답을 기다리는 사이 로그아웃했거나 다른 회원이 로그인했다면 결과와 실패를 모두 버린다.
  Future<void> refreshMember() async {
    final requestedMemberId = _session.currentMember?.memberId;
    final Member member;
    try {
      member = await _repository.fetchMe();
    } on Object {
      if (_isStillCurrent(requestedMemberId)) {
        rethrow;
      }
      return;
    }
    if (_isStillCurrent(requestedMemberId)) {
      _session.updateMember(member);
    }
  }

  /// 닉네임을 바꾸고 응답 회원으로 보관 중인 회원을 갱신한다.
  /// 응답을 기다리는 사이 세션이 바뀌었다면 결과를 버린다. 서버 오류는 그대로 던진다.
  Future<void> changeNickname(String nickname) async {
    final requestedMemberId = _session.currentMember?.memberId;
    final member = await _repository.changeNickname(nickname: nickname);
    if (_isStillCurrent(requestedMemberId)) {
      _session.updateMember(member);
    }
  }

  /// 프로필 사진을 교체하고 응답 회원으로 보관 중인 회원을 갱신한다.
  /// 응답을 기다리는 사이 세션이 바뀌었다면 결과를 버린다. 서버 오류는 그대로 던진다.
  Future<void> replaceProfileImage(ProfileImageFile image) async {
    final requestedMemberId = _session.currentMember?.memberId;
    final member = await _repository.replaceProfileImage(image);
    if (_isStillCurrent(requestedMemberId)) {
      _session.updateMember(member);
    }
  }

  bool _isStillCurrent(String? requestedMemberId) =>
      _readStatus() == AuthStatus.signedIn &&
      _session.currentMember?.memberId == requestedMemberId;

  /// 회원 탈퇴 후 로컬 세션을 지운다. 서버가 이미 토큰을 폐기했으므로 서버 로그아웃은 부르지 않는다.
  /// Apple 회원은 먼저 Apple 연동을 해제한다(재인증 → revoke). 사용자가 재인증을 취소하면
  /// 아무것도 바꾸지 않고 false를 돌려주고, 해제에 실패하면 예외를 던지며 탈퇴하지 않는다.
  /// 서버 호출이 실패하면 예외를 그대로 던지고 세션은 유지한다.
  /// 서버 탈퇴 뒤 Firebase 사용자 삭제와 세션 정리는 실패해도 무시한다.
  /// [beforeSigningOut]은 세션을 지우기 직전에 호출해 다른 상태를 함께 비울 수 있게 한다.
  Future<bool> deleteAccount({void Function()? beforeSigningOut}) async {
    if (_session.currentMember?.loginType == LoginType.apple) {
      try {
        await _socialCredentialProvider.revokeAppleConnection();
      } on SocialSignInCancelledException {
        return false;
      }
    }
    await _repository.deleteAccount();
    beforeSigningOut?.call();
    try {
      await _socialCredentialProvider.deleteFirebaseUser();
    } on Object {
      // 서버 탈퇴가 끝났으므로 Firebase 사용자 삭제 실패는 무시한다.
    }
    await _clearSocialSession();
    await _session.signOut();
    return true;
  }

  /// 서버 로그아웃 실패는 무시하고 로컬 세션은 항상 지운다.
  Future<void> logout() async {
    try {
      await _repository.logout();
    } on Exception {
      // 서버에 닿지 않아도 기기에서는 로그아웃돼야 한다.
    }
    await _clearSocialSession();
    await _session.signOut();
  }

  /// Firebase·Google 세션을 정리한다. 실패해도 로그아웃을 막지 않는다.
  Future<void> _clearSocialSession() async {
    try {
      await _socialCredentialProvider.signOut();
    } on Object {
      // 소셜 세션 정리 실패는 무시한다.
    }
  }
}
