import 'package:flutter_test/flutter_test.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:teeq/core/config/app_config.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/features/auth/data/sign_in_with_apple_credential_provider.dart';
import 'package:teeq/features/auth/domain/apple_credential_provider.dart';

const _config = AppConfig(
  apiBaseUrl: 'https://api.example.test',
  appleServiceId: 'kr.co.teeq.app.service',
  appleRedirectUri: 'https://api.example.test/api/auth/apple/callback',
);

AuthorizationCredentialAppleID _credential({String? identityToken}) {
  return AuthorizationCredentialAppleID(
    userIdentifier: null,
    givenName: null,
    familyName: null,
    authorizationCode: 'code',
    email: null,
    identityToken: identityToken,
    state: null,
  );
}

void main() {
  test(
    'iosRequest_passesNoWebAuthenticationOptions_andReturnsIdentityToken',
    () async {
      List<AppleIDAuthorizationScopes>? requestedScopes;
      WebAuthenticationOptions? requestedOptions;
      final provider = SignInWithAppleCredentialProvider(
        config: _config,
        isAndroid: false,
        requester: ({required scopes, webAuthenticationOptions}) async {
          requestedScopes = scopes;
          requestedOptions = webAuthenticationOptions;
          return _credential(identityToken: 'apple-token');
        },
      );

      final token = await provider.requestIdentityToken();

      expect(token, 'apple-token');
      expect(requestedScopes, [AppleIDAuthorizationScopes.email]);
      expect(requestedOptions, isNull);
    },
  );

  test('androidRequest_passesServiceIdAndRedirectUri', () async {
    WebAuthenticationOptions? requestedOptions;
    final provider = SignInWithAppleCredentialProvider(
      config: _config,
      isAndroid: true,
      requester: ({required scopes, webAuthenticationOptions}) async {
        requestedOptions = webAuthenticationOptions;
        return _credential(identityToken: 'apple-token');
      },
    );

    await provider.requestIdentityToken();

    expect(requestedOptions!.clientId, 'kr.co.teeq.app.service');
    expect(
      requestedOptions!.redirectUri,
      Uri.parse('https://api.example.test/api/auth/apple/callback'),
    );
  });

  test('canceledAuthorization_throwsAppleSignInCancelled', () async {
    final provider = SignInWithAppleCredentialProvider(
      config: _config,
      isAndroid: false,
      requester: ({required scopes, webAuthenticationOptions}) async {
        throw const SignInWithAppleAuthorizationException(
          code: AuthorizationErrorCode.canceled,
          message: 'canceled',
        );
      },
    );

    expect(
      provider.requestIdentityToken(),
      throwsA(isA<AppleSignInCancelledException>()),
    );
  });

  test('missingIdentityToken_throwsUnexpectedException', () async {
    final provider = SignInWithAppleCredentialProvider(
      config: _config,
      isAndroid: false,
      requester: ({required scopes, webAuthenticationOptions}) async =>
          _credential(),
    );

    expect(
      provider.requestIdentityToken(),
      throwsA(isA<UnexpectedException>()),
    );
  });
}
