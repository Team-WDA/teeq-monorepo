/// 로그인 상태.
enum AuthStatus {
  /// 저장된 인증 정보를 복원하는 중이라 아직 알 수 없는 상태.
  unknown,

  /// 로그아웃 상태.
  signedOut,

  /// 로그인 상태.
  signedIn,
}
