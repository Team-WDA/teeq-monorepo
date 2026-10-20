import 'package:teeq/core/auth/auth_session.dart';
import 'package:teeq/core/auth/auth_status.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/auth/token_storage.dart';
import 'package:teeq/features/auth/domain/apple_credential_provider.dart';
import 'package:teeq/features/auth/domain/auth_repository.dart';
import 'package:teeq/features/auth/domain/profile_image_file.dart';

/// 화면이 부르는 인증 흐름(복원, 로그인, 가입, 로그아웃)을 한곳에 모은다.
/// 협력자를 생성자로 받아 dio와 Riverpod을 모른 채 단위 테스트할 수 있다.
class AuthFlow {
  AuthFlow({
    required this._repository,
    required this._appleCredentialProvider,
    required this._session,
    required this._tokenStorage,
    required this._readStatus,
    required this._reportError,
  });

  final AuthRepository _repository;
  final AppleCredentialProvider _appleCredentialProvider;
  final AuthSession _session;
  final TokenStorage _tokenStorage;
  final AuthStatus Function() _readStatus;
  final void Function(Object error, {bool blocking}) _reportError;

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

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final result = await _repository.login(email: email, password: password);
    await _session.signIn(result);
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String nickname,
    required bool serviceTermsAgreed,
    required bool privacyPolicyAgreed,
  }) async {
    final result = await _repository.signUp(
      email: email,
      password: password,
      nickname: nickname,
      serviceTermsAgreed: serviceTermsAgreed,
      privacyPolicyAgreed: privacyPolicyAgreed,
    );
    await _session.signIn(result);
  }

  /// Apple로 로그인한다. 사용자가 취소하면 상태를 바꾸지 않고 false를 돌려준다.
  Future<bool> signInWithApple() async {
    final String identityToken;
    try {
      identityToken = await _appleCredentialProvider.requestIdentityToken();
    } on AppleSignInCancelledException {
      return false;
    }
    final result = await _repository.socialLogin(credential: identityToken);
    await _session.signIn(result);
    return true;
  }

  /// 가입을 완료하고 돌려받은 회원으로 보관 중인 회원을 갱신한다.
  Future<void> completeSignup({
    required String nickname,
    required bool serviceTermsAgreed,
    required bool privacyPolicyAgreed,
  }) async {
    final member = await _repository.completeSignup(
      nickname: nickname,
      serviceTermsAgreed: serviceTermsAgreed,
      privacyPolicyAgreed: privacyPolicyAgreed,
    );
    await _session.restored(member);
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

  /// 비밀번호를 바꾸고 새 토큰만 저장한다. 응답에 이메일이 없어 보관 중인 회원은 그대로 둔다.
  /// 응답을 기다리는 사이 세션이 바뀌었다면 토큰을 저장하지 않는다. 서버 오류는 그대로 던진다.
  Future<void> changePassword({
    required String current,
    required String next,
  }) async {
    final requestedMemberId = _session.currentMember?.memberId;
    final result = await _repository.changePassword(
      currentPassword: current,
      newPassword: next,
    );
    if (_isStillCurrent(requestedMemberId)) {
      await _tokenStorage.save(result.tokens);
    }
  }

  bool _isStillCurrent(String? requestedMemberId) =>
      _readStatus() == AuthStatus.signedIn &&
      _session.currentMember?.memberId == requestedMemberId;

  /// 회원 탈퇴 후 로컬 세션을 지운다. 서버가 이미 토큰을 폐기했으므로 서버 로그아웃은 부르지 않는다.
  /// 서버 호출이 실패하면 예외를 그대로 던지고 세션은 유지한다.
  /// [beforeSigningOut]은 세션을 지우기 직전에 호출해 다른 상태를 함께 비울 수 있게 한다.
  Future<void> deleteAccount({void Function()? beforeSigningOut}) async {
    await _repository.deleteAccount();
    beforeSigningOut?.call();
    await _session.signOut();
  }

  /// 서버 로그아웃 실패는 무시하고 로컬 세션은 항상 지운다.
  Future<void> logout() async {
    try {
      await _repository.logout();
    } on Exception {
      // 서버에 닿지 않아도 기기에서는 로그아웃돼야 한다.
    }
    await _session.signOut();
  }
}
