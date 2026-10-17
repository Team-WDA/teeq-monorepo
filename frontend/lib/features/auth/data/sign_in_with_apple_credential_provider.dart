import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:teeq/core/config/app_config.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/features/auth/domain/apple_credential_provider.dart';

part 'sign_in_with_apple_credential_provider.g.dart';

typedef AppleCredentialRequester =
    Future<AuthorizationCredentialAppleID> Function({
      required List<AppleIDAuthorizationScopes> scopes,
      WebAuthenticationOptions? webAuthenticationOptions,
    });

@Riverpod(keepAlive: true)
AppleCredentialProvider appleCredentialProvider(Ref ref) {
  return SignInWithAppleCredentialProvider(
    config: ref.watch(appConfigProvider),
    isAndroid: Platform.isAndroid,
  );
}

/// `sign_in_with_apple` 플러그인으로 identity token을 받는 구현.
/// iOS는 네이티브 시트, Android는 웹 흐름(Services ID와 콜백 주소 필요)을 쓴다.
final class SignInWithAppleCredentialProvider
    implements AppleCredentialProvider {
  SignInWithAppleCredentialProvider({
    required this._config,
    required this._isAndroid,
    AppleCredentialRequester? requester,
  }) : _requester = requester ?? SignInWithApple.getAppleIDCredential;

  final AppConfig _config;
  final bool _isAndroid;
  final AppleCredentialRequester _requester;

  @override
  Future<String> requestIdentityToken() async {
    final AuthorizationCredentialAppleID credential;
    try {
      credential = await _requester(
        scopes: const [AppleIDAuthorizationScopes.email],
        webAuthenticationOptions: _isAndroid
            ? WebAuthenticationOptions(
                clientId: _config.appleServiceId,
                redirectUri: Uri.parse(_config.appleRedirectUri),
              )
            : null,
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        throw const AppleSignInCancelledException();
      }
      rethrow;
    }
    final identityToken = credential.identityToken;
    if (identityToken == null) {
      throw const UnexpectedException('Apple identity token 없음');
    }
    return identityToken;
  }
}
