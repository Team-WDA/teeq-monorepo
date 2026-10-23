import 'package:teeq/features/auth/domain/social_credential_provider.dart';

/// 호출 순서를 [calls]에 기록하고 미리 정한 결과 또는 오류를 돌려주는 테스트용 소셜 자격 증명 제공자.
class FakeSocialCredentialProvider implements SocialCredentialProvider {
  FakeSocialCredentialProvider({
    this.signInError,
    this.revokeError,
    this.deleteFirebaseUserError,
    this.signOutError,
  });

  /// 지정하면 [signInWithApple], [signInWithGoogle]이 이 오류를 던진다.
  final Object? signInError;

  /// 지정하면 [revokeAppleConnection]이 이 오류를 던진다.
  final Object? revokeError;

  /// 지정하면 [deleteFirebaseUser]가 이 오류를 던진다.
  final Object? deleteFirebaseUserError;

  /// 지정하면 [signOut]이 이 오류를 던진다.
  final Object? signOutError;

  /// 호출한 메서드 이름 순서.
  final List<String> calls = [];

  @override
  Future<String> signInWithApple() async {
    calls.add('signInWithApple');
    _throwIfSet(signInError);
    return 'apple-token';
  }

  @override
  Future<String> signInWithGoogle() async {
    calls.add('signInWithGoogle');
    _throwIfSet(signInError);
    return 'google-token';
  }

  @override
  Future<String> fetchLatestIdToken() async {
    calls.add('fetchLatestIdToken');
    return 'latest-token';
  }

  @override
  Future<void> revokeAppleConnection() async {
    calls.add('revokeAppleConnection');
    _throwIfSet(revokeError);
  }

  @override
  Future<void> deleteFirebaseUser() async {
    calls.add('deleteFirebaseUser');
    _throwIfSet(deleteFirebaseUserError);
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    _throwIfSet(signOutError);
  }

  void _throwIfSet(Object? error) {
    if (error != null) {
      throw error;
    }
  }
}
