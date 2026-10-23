import 'package:teeq/core/auth/auth_session.dart';
import 'package:teeq/core/auth/auth_status.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/auth/sign_in_result.dart';
import 'package:teeq/core/auth/token_storage.dart';
import 'package:teeq/features/auth/domain/auth_credential_provider.dart';
import 'package:teeq/features/auth/domain/auth_repository.dart';
import 'package:teeq/features/auth/domain/profile_image_file.dart';
import 'package:teeq/features/auth/domain/signup_draft.dart';

/// 로그인 시도의 결과. 취소와 가입 필요는 오류가 아니라 화면이 분기할 결과다.
enum SignInOutcome {
  /// 가입된 회원으로 로그인했다.
  signedIn,

  /// 사용자가 로그인을 취소했다. 상태를 바꾸지 않는다.
  cancelled,

  /// 아직 가입하지 않은 계정이다. 약관·닉네임 단계로 이어가야 한다.
  signupRequired,
}

/// 가입 시도의 결과. 닉네임 중복 사전 확인은 오류가 아니라 화면이 알릴 결과다.
enum SignupOutcome {
  /// 가입을 마치고(또는 이미 가입된 계정으로) 로그인했다.
  signedIn,

  /// 이미 쓰는 닉네임이라 Firebase 계정을 만들지 않고 멈췄다.
  nicknameUnavailable,
}

/// 화면이 부르는 인증 흐름(복원, 로그인, 가입, 로그아웃)을 한곳에 모은다.
/// 협력자를 생성자로 받아 dio와 Riverpod을 모른 채 단위 테스트할 수 있다.
class AuthFlow {
  AuthFlow({
    required this._repository,
    required this._credentialProvider,
    required this._session,
    required this._tokenStorage,
    required this._readStatus,
    required this._reportError,
    required this._isSignupRequired,
    required this._isStateConflict,
    required this._isEmailAlreadyInUse,
    required this._isInvalidCredentials,
    required this._isDefinitiveSignupRejection,
  });

  final AuthRepository _repository;
  final AuthCredentialProvider _credentialProvider;
  final AuthSession _session;
  final TokenStorage _tokenStorage;
  final AuthStatus Function() _readStatus;
  final void Function(Object error, {bool blocking}) _reportError;

  /// 로그인 오류가 "가입이 필요한 계정(AUTH_SIGNUP_REQUIRED)"인지 판정한다.
  /// 오류 객체를 해석하려면 dio에 의존해야 하므로 domain 밖에서 주입한다.
  final bool Function(Object error) _isSignupRequired;

  /// 가입 오류가 "서버는 이미 가입이 끝났다(STATE_CONFLICT)"인지 판정한다.
  final bool Function(Object error) _isStateConflict;

  /// Firebase 계정 생성 오류가 "이미 가입된 이메일"인지 판정한다.
  final bool Function(Object error) _isEmailAlreadyInUse;

  /// 이메일 로그인 오류가 이메일 또는 비밀번호 불일치인지 판정한다.
  /// 네트워크 오류나 시도 과다 같은 다른 오류와 구분하기 위해 쓴다.
  final bool Function(Object error) _isInvalidCredentials;

  /// 가입 오류가 서버가 요청을 거절한 확정 실패(HTTP 400, 401)인지 판정한다.
  /// 네트워크 오류, 5xx, 409(닉네임 중복·이미 가입)는 확정 실패가 아니다.
  final bool Function(Object error) _isDefinitiveSignupRejection;

  /// 앱 시작 시 저장된 토큰으로 로그인 상태를 복원한다. 이미 복원된 뒤에는 아무것도 하지 않는다.
  /// 실패하면 상태와 토큰을 그대로 두고 오류만 알린다(오프라인 시작이 토큰을 지우면 안 된다).
  /// 저장된 토큰이 없으면 남아 있을 수 있는 Firebase·Google 세션도 함께 정리한다.
  Future<void> restore() async {
    if (_readStatus() != AuthStatus.unknown) {
      return;
    }
    try {
      final tokens = await _tokenStorage.read();
      if (tokens == null) {
        await _clearCredentialSession();
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
  Future<SignInOutcome> signInWithApple() =>
      _signInWith(_credentialProvider.signInWithApple);

  /// Google로 로그인한다.
  Future<SignInOutcome> signInWithGoogle() =>
      _signInWith(_credentialProvider.signInWithGoogle);

  /// 이메일·비밀번호로 로그인한다. 가입하지 않은 계정이면 [SignInOutcome.signupRequired]를 돌려주고
  /// Firebase 로그인은 유지한다(이어지는 가입 단계가 현재 세션의 ID token을 쓴다).
  Future<SignInOutcome> signInWithEmail({
    required String email,
    required String password,
  }) => _signInWith(
    () => _credentialProvider.signInWithEmail(email: email, password: password),
  );

  Future<SignInOutcome> _signInWith(
    Future<String> Function() requestCredential,
  ) async {
    final String credential;
    try {
      credential = await requestCredential();
    } on SignInCancelledException {
      return SignInOutcome.cancelled;
    }
    final SignInResult result;
    try {
      result = await _repository.login(credential: credential);
    } on Object catch (error) {
      if (_isSignupRequired(error)) {
        return SignInOutcome.signupRequired;
      }
      rethrow;
    }
    await _session.signIn(result);
    return SignInOutcome.signedIn;
  }

  /// 약관 동의와 닉네임으로 가입을 마치고 로그인한다. 가입 방식은 [draft]의 모드가 정한다.
  ///
  /// - [SignupMode.firebaseSession]: 현재 Firebase 세션의 최신 ID token으로 가입한다.
  /// - [SignupMode.emailSignup]: 닉네임 사용 가능 여부를 먼저 확인하고(불가면 중단),
  ///   Firebase 계정을 만든 뒤 가입한다. 이미 있는 이메일이면 입력한 비밀번호로 로그인해
  ///   회원이 있으면 그대로 로그인하고, 없으면 중단됐던 가입을 마무리한다.
  ///
  /// 서버가 이미 가입을 마친 상태(STATE_CONFLICT)라면 같은 token으로 로그인을 한 번 다시 시도한다.
  /// 이번 시도에서 만든 Firebase 계정은 서버가 400/401로 확정 거절했을 때만 지운다.
  /// 그 밖의 오류(중복 닉네임, 네트워크, 5xx 등)는 계정을 지우지 않고 그대로 던진다.
  Future<SignupOutcome> completeSignup({
    required SignupDraft draft,
    required String nickname,
  }) async {
    switch (draft.mode) {
      case SignupMode.firebaseSession:
        await _signUpWithCredential(
          credential: await _credentialProvider.fetchLatestIdToken(),
          draft: draft,
          nickname: nickname,
          isAccountCreatedByThisAttempt: false,
        );
        return SignupOutcome.signedIn;
      case SignupMode.emailSignup:
        return _completeEmailSignup(draft: draft, nickname: nickname);
    }
  }

  Future<SignupOutcome> _completeEmailSignup({
    required SignupDraft draft,
    required String nickname,
  }) async {
    if (!await _repository.checkNicknameAvailability(nickname: nickname)) {
      return SignupOutcome.nicknameUnavailable;
    }
    final String credential;
    try {
      credential = await _credentialProvider.createEmailAccount(
        email: draft.email,
        password: draft.password,
      );
    } on Object catch (error) {
      if (!_isEmailAlreadyInUse(error)) {
        rethrow;
      }
      await _recoverExistingEmailAccount(
        draft: draft,
        nickname: nickname,
        emailAlreadyInUseError: error,
      );
      return SignupOutcome.signedIn;
    }
    await _signUpWithCredential(
      credential: credential,
      draft: draft,
      nickname: nickname,
      isAccountCreatedByThisAttempt: true,
    );
    return SignupOutcome.signedIn;
  }

  /// 이미 있는 이메일이면 입력한 비밀번호로 로그인해 본인 계정인지 확인한다.
  /// 이메일 또는 비밀번호가 맞지 않아 로그인에 실패하면(남의 계정이거나 비밀번호가 다르면) 원래의 "이미 사용 중인 이메일" 오류를 던진다.
  /// 네트워크 오류나 시도 과다 같은 다른 실패는 그 오류를 그대로 던져 사용자가 이메일이 쓰였다고 오해하지 않게 한다.
  /// 로그인에 성공하면 서버 회원이 있는 경우 그대로 로그인하고, 없으면 중단됐던 가입을 마무리한다.
  Future<void> _recoverExistingEmailAccount({
    required SignupDraft draft,
    required String nickname,
    required Object emailAlreadyInUseError,
  }) async {
    final String credential;
    try {
      credential = await _credentialProvider.signInWithEmail(
        email: draft.email,
        password: draft.password,
      );
    } on Object catch (error) {
      if (_isInvalidCredentials(error)) {
        throw emailAlreadyInUseError;
      }
      rethrow;
    }
    final SignInResult result;
    try {
      result = await _repository.login(credential: credential);
    } on Object catch (error) {
      if (!_isSignupRequired(error)) {
        rethrow;
      }
      await _signUpWithCredential(
        credential: credential,
        draft: draft,
        nickname: nickname,
        isAccountCreatedByThisAttempt: false,
      );
      return;
    }
    await _session.signIn(result);
  }

  Future<void> _signUpWithCredential({
    required String credential,
    required SignupDraft draft,
    required String nickname,
    required bool isAccountCreatedByThisAttempt,
  }) async {
    final SignInResult result;
    try {
      result = await _repository.signUp(
        credential: credential,
        nickname: nickname,
        serviceTermsAgreed: draft.isServiceTermsAgreed,
        privacyPolicyAgreed: draft.isPrivacyPolicyAgreed,
      );
    } on Object catch (error) {
      if (_isStateConflict(error)) {
        await _session.signIn(await _repository.login(credential: credential));
        return;
      }
      if (isAccountCreatedByThisAttempt &&
          _isDefinitiveSignupRejection(error)) {
        await _deleteCreatedAccountBestEffort();
      }
      rethrow;
    }
    await _session.signIn(result);
  }

  /// 이메일 회원이 현재 비밀번호를 확인받고 새 비밀번호로 바꾼다. 서버는 관여하지 않는다.
  /// 현재 비밀번호가 틀리면 구현이 던지는 현재 비밀번호 오류를 그대로 전한다.
  Future<void> changePassword({
    required String current,
    required String next,
  }) async {
    final email = _session.currentMember?.email;
    if (email == null) {
      throw StateError('이메일 정보가 없어 비밀번호를 바꿀 수 없다');
    }
    await _credentialProvider.changeEmailPassword(
      email: email,
      currentPassword: current,
      newPassword: next,
    );
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
  /// Firebase 사용자 삭제는 서버가 맡으므로 앱은 지우지 않고, 서버 탈퇴 뒤 Firebase·Google 로그인
  /// 세션 정리는 실패해도 무시한다.
  /// [beforeSigningOut]은 세션을 지우기 직전에 호출해 다른 상태를 함께 비울 수 있게 한다.
  Future<bool> deleteAccount({void Function()? beforeSigningOut}) async {
    if (_session.currentMember?.loginType == LoginType.apple) {
      try {
        await _credentialProvider.revokeAppleConnection();
      } on SignInCancelledException {
        return false;
      }
    }
    await _repository.deleteAccount();
    beforeSigningOut?.call();
    await _clearCredentialSession();
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
    await _clearCredentialSession();
    await _session.signOut();
  }

  /// Firebase·Google 세션을 정리한다. 실패해도 로그아웃을 막지 않는다.
  Future<void> _clearCredentialSession() async {
    try {
      await _credentialProvider.signOut();
    } on Object {
      // 세션 정리 실패는 무시한다.
    }
  }

  /// 방금 만든 Firebase 계정을 지운다. 실패해도 원래의 가입 오류 전달을 막지 않는다.
  Future<void> _deleteCreatedAccountBestEffort() async {
    try {
      await _credentialProvider.deleteCreatedAccount();
    } on Object {
      // 정리 실패는 무시한다.
    }
  }
}
