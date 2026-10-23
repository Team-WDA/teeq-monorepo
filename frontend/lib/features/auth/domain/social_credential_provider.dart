/// 소셜 로그인(Apple, Google) 자격 증명 계약. 구현은 Firebase와 각 SDK를 감싼다.
/// 모든 로그인 방식은 서버에 보낼 Firebase ID token을 돌려준다.
abstract interface class SocialCredentialProvider {
  /// Apple 로그인 시트를 열고 Firebase ID token을 돌려준다.
  /// 사용자가 취소하면 [SocialSignInCancelledException]을 던진다.
  Future<String> signInWithApple();

  /// Google 로그인 화면을 열고 Firebase ID token을 돌려준다.
  /// 사용자가 취소하면 [SocialSignInCancelledException]을 던진다.
  Future<String> signInWithGoogle();

  /// 이미 Firebase에 로그인한 사용자의 최신 ID token을 돌려준다(가입 단계에서 쓴다).
  Future<String> fetchLatestIdToken();

  /// Apple 연동을 해제한다. 재인증으로 authorization code를 받아 revoke한다.
  /// 사용자가 재인증을 취소하면 [SocialSignInCancelledException]을 던진다.
  /// 그 밖의 모든 실패(code 없음, revoke 실패, 다른 Apple 계정 등)는 구현이 Apple 연동 해제 실패 예외로 던진다.
  Future<void> revokeAppleConnection();

  /// Firebase 사용자를 삭제한다.
  Future<void> deleteFirebaseUser();

  /// Firebase와 Google 로그인 세션을 정리한다.
  Future<void> signOut();
}

/// 사용자가 소셜 로그인을 취소했다. 오류가 아니므로 화면에 알리지 않는다.
final class SocialSignInCancelledException implements Exception {
  const SocialSignInCancelledException();
}
