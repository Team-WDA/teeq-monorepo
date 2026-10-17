import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/auth/auth_session.dart';
import 'package:teeq/core/auth/auth_status.dart';
import 'package:teeq/core/auth/auth_status_controller.dart';
import 'package:teeq/core/auth/auth_tokens.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/auth/sign_in_result.dart';
import 'package:teeq/core/auth/token_storage.dart';
import 'package:teeq/features/auth/domain/apple_credential_provider.dart';
import 'package:teeq/features/auth/domain/auth_flow.dart';

import '../../../../support/fake_auth_repository.dart';
import '../../../../support/fake_token_storage.dart';

const _tokens = AuthTokens(accessToken: 'access', refreshToken: 'refresh');

const _member = Member(
  memberId: 'member-1',
  nickname: '티큐',
  hasAiCharacter: false,
  loginType: LoginType.apple,
);

class _FakeAppleCredentialProvider implements AppleCredentialProvider {
  _FakeAppleCredentialProvider({this.error});

  final Object? error;

  @override
  Future<String> requestIdentityToken() async {
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return 'apple-token';
  }
}

class _Harness {
  _Harness({
    FakeAuthRepository? repository,
    Object? appleError,
    AuthTokens? storedTokens,
  }) : repository = repository ?? FakeAuthRepository(),
       tokenStorage = FakeTokenStorage(storedTokens: storedTokens) {
    container = ProviderContainer(
      overrides: [tokenStorageProvider.overrideWithValue(tokenStorage)],
    );
    flow = AuthFlow(
      repository: this.repository,
      appleCredentialProvider: _FakeAppleCredentialProvider(error: appleError),
      session: container.read(authSessionProvider),
      tokenStorage: tokenStorage,
      readStatus: () => container.read(authStatusControllerProvider),
      reportError: (error, {bool blocking = false}) =>
          reported.add((error: error, blocking: blocking)),
    );
  }

  final FakeAuthRepository repository;
  final FakeTokenStorage tokenStorage;
  final List<({Object error, bool blocking})> reported = [];
  late final ProviderContainer container;
  late final AuthFlow flow;

  AuthStatus get status => container.read(authStatusControllerProvider);
  Member? get currentMember => container.read(currentMemberControllerProvider);
}

void main() {
  test('restore_noTokens_signsOut', () async {
    final harness = _Harness();

    await harness.flow.restore();

    expect(harness.status, AuthStatus.signedOut);
    expect(harness.repository.fetchMeCount, 0);
  });

  test('restore_success_marksSignedInWithMember', () async {
    final harness = _Harness(
      repository: FakeAuthRepository(member: _member),
      storedTokens: _tokens,
    );

    await harness.flow.restore();

    expect(harness.status, AuthStatus.signedIn);
    expect(harness.currentMember, _member);
    expect(harness.tokenStorage.storedTokens, _tokens);
  });

  test(
    'restore_networkError_keepsTokensAndStatusUnknown_andReportsBlocking',
    () async {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/members/me'),
        type: DioExceptionType.connectionError,
      );
      final harness = _Harness(
        repository: FakeAuthRepository(fetchMeError: error),
        storedTokens: _tokens,
      );

      await harness.flow.restore();

      expect(harness.status, AuthStatus.unknown);
      expect(harness.tokenStorage.storedTokens, _tokens);
      expect(harness.tokenStorage.clearCount, 0);
      expect(harness.reported.single.error, error);
      expect(harness.reported.single.blocking, isTrue);
    },
  );

  test('restore_authError_reportedToErrorHandler', () async {
    final error = Exception('unauthenticated');
    final harness = _Harness(
      repository: FakeAuthRepository(fetchMeError: error),
      storedTokens: _tokens,
    );

    await harness.flow.restore();

    expect(harness.reported.single.error, error);
    expect(harness.reported.single.blocking, isTrue);
  });

  test('restore_whenNotUnknown_doesNothing', () async {
    final harness = _Harness(
      repository: FakeAuthRepository(member: _member),
      storedTokens: _tokens,
    );
    harness.container
        .read(authStatusControllerProvider.notifier)
        .markSignedOut();

    await harness.flow.restore();

    expect(harness.status, AuthStatus.signedOut);
    expect(harness.tokenStorage.readCount, 0);
    expect(harness.repository.fetchMeCount, 0);
  });

  test('signInWithApple_cancelled_returnsFalseAndKeepsState', () async {
    final harness = _Harness(appleError: AppleSignInCancelledException());

    final signedIn = await harness.flow.signInWithApple();

    expect(signedIn, isFalse);
    expect(harness.status, AuthStatus.unknown);
    expect(harness.reported, isEmpty);
    expect(harness.repository.socialLoginCredential, isNull);
    expect(harness.tokenStorage.savedTokens, isNull);
  });

  test('signInWithApple_success_signsInWithMember', () async {
    final harness = _Harness(
      repository: FakeAuthRepository(
        signInResult: const SignInResult(tokens: _tokens, member: _member),
      ),
    );

    final signedIn = await harness.flow.signInWithApple();

    expect(signedIn, isTrue);
    expect(harness.repository.socialLoginCredential, 'apple-token');
    expect(harness.status, AuthStatus.signedIn);
    expect(harness.currentMember, _member);
    expect(harness.tokenStorage.savedTokens, _tokens);
  });

  test('completeSignup_updatesCurrentMember', () async {
    final harness = _Harness(repository: FakeAuthRepository(member: _member));

    await harness.flow.completeSignup(
      nickname: '티큐',
      serviceTermsAgreed: true,
      privacyPolicyAgreed: true,
    );

    expect(harness.currentMember, _member);
  });

  test('logout_whenServerFails_stillSignsOut', () async {
    final harness = _Harness(
      repository: FakeAuthRepository(logoutError: Exception('server down')),
      storedTokens: _tokens,
    );
    harness.container
        .read(authStatusControllerProvider.notifier)
        .markSignedIn();

    await harness.flow.logout();

    expect(harness.status, AuthStatus.signedOut);
    expect(harness.currentMember, isNull);
    expect(harness.tokenStorage.storedTokens, isNull);
  });
}
