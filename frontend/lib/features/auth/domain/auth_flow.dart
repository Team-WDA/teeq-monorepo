import 'package:teeq/core/auth/auth_session.dart';
import 'package:teeq/core/auth/auth_status.dart';
import 'package:teeq/core/auth/token_storage.dart';
import 'package:teeq/features/auth/domain/apple_credential_provider.dart';
import 'package:teeq/features/auth/domain/auth_repository.dart';

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
