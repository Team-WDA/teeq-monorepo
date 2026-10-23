import 'dart:async';

import 'package:teeq/features/auth/domain/auth_credential_provider.dart';

/// 호출 순서를 [calls]에 기록하고 미리 정한 결과 또는 오류를 돌려주는 테스트용 자격 증명 제공자.
class FakeAuthCredentialProvider implements AuthCredentialProvider {
  FakeAuthCredentialProvider({
    this.signInError,
    this.emailSignInError,
    this.createAccountError,
    this.changePasswordError,
    this.revokeError,
    this.deleteCreatedAccountError,
    this.signOutError,
  });

  /// 지정하면 [signInWithApple], [signInWithGoogle]이 이 오류를 던진다.
  final Object? signInError;

  /// 지정하면 [signInWithEmail]이 이 오류를 던진다.
  final Object? emailSignInError;

  /// 지정하면 [createEmailAccount]가 이 오류를 던진다.
  final Object? createAccountError;

  /// 지정하면 [changeEmailPassword]가 이 오류를 던진다.
  final Object? changePasswordError;

  /// 지정하면 [revokeAppleConnection]이 이 오류를 던진다.
  final Object? revokeError;

  /// 지정하면 [deleteCreatedAccount]가 이 오류를 던진다.
  final Object? deleteCreatedAccountError;

  /// 지정하면 [signOut]이 이 오류를 던진다.
  final Object? signOutError;

  /// 지정하면 [changeEmailPassword]가 이 게이트가 완료될 때까지 응답을 미룬다.
  Completer<void>? changePasswordGate;

  /// 호출한 메서드 이름 순서.
  final List<String> calls = [];

  /// 마지막 이메일 로그인·계정 생성 입력.
  ({String email, String password})? lastEmailCredentials;

  /// 마지막 비밀번호 변경 입력.
  ({String email, String currentPassword, String newPassword})?
  lastPasswordChange;

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
  Future<String> signInWithEmail({
    required String email,
    required String password,
  }) async {
    calls.add('signInWithEmail');
    lastEmailCredentials = (email: email, password: password);
    _throwIfSet(emailSignInError);
    return 'email-sign-in-token';
  }

  @override
  Future<String> createEmailAccount({
    required String email,
    required String password,
  }) async {
    calls.add('createEmailAccount');
    lastEmailCredentials = (email: email, password: password);
    _throwIfSet(createAccountError);
    return 'email-created-token';
  }

  @override
  Future<String> fetchLatestIdToken() async {
    calls.add('fetchLatestIdToken');
    return 'latest-token';
  }

  @override
  Future<void> changeEmailPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    calls.add('changeEmailPassword');
    lastPasswordChange = (
      email: email,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    await changePasswordGate?.future;
    _throwIfSet(changePasswordError);
  }

  @override
  Future<void> revokeAppleConnection() async {
    calls.add('revokeAppleConnection');
    _throwIfSet(revokeError);
  }

  @override
  Future<void> deleteCreatedAccount() async {
    calls.add('deleteCreatedAccount');
    _throwIfSet(deleteCreatedAccountError);
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
