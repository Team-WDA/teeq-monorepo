/// Apple 로그인 자격 증명(identity token) 발급 계약.
abstract interface class AppleCredentialProvider {
  /// Apple 로그인 시트·웹 흐름을 열고 identity token을 돌려준다.
  /// 사용자가 취소하면 [AppleSignInCancelledException]을 던진다.
  Future<String> requestIdentityToken();
}

/// 사용자가 Apple 로그인을 취소했다. 오류가 아니므로 화면에 알리지 않는다.
final class AppleSignInCancelledException implements Exception {
  const AppleSignInCancelledException();
}
