import 'dart:async';
import 'dart:typed_data';

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
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/features/auth/data/auth_repository_impl.dart';
import 'package:teeq/features/auth/data/firebase_auth_credential_provider.dart';
import 'package:teeq/features/auth/domain/auth_flow.dart';
import 'package:teeq/features/auth/domain/profile_image_file.dart';
import 'package:teeq/features/auth/domain/signup_draft.dart';
import 'package:teeq/features/auth/domain/auth_credential_provider.dart';
import 'package:teeq/features/auth/presentation/auth_flow_provider.dart';

import '../../../../support/fake_auth_repository.dart';
import '../../../../support/fake_auth_credential_provider.dart';
import '../../../../support/fake_token_storage.dart';

const _tokens = AuthTokens(accessToken: 'access', refreshToken: 'refresh');

const _sessionDraft = SignupDraft(
  mode: SignupMode.firebaseSession,
  email: '',
  password: '',
  isServiceTermsAgreed: true,
  isPrivacyPolicyAgreed: true,
);

const _emailDraft = SignupDraft(
  mode: SignupMode.emailSignup,
  email: 'user@example.com',
  password: 'Abcdef12',
  isServiceTermsAgreed: true,
  isPrivacyPolicyAgreed: true,
);

const _member = Member(
  memberId: 'member-1',
  nickname: '티큐',
  hasAiCharacter: false,
  loginType: LoginType.apple,
);

class _Harness {
  _Harness({
    FakeAuthRepository? repository,
    FakeAuthCredentialProvider? credentialProvider,
    AuthTokens? storedTokens,
  }) : repository = repository ?? FakeAuthRepository(),
       credentialProvider = credentialProvider ?? FakeAuthCredentialProvider(),
       tokenStorage = FakeTokenStorage(storedTokens: storedTokens) {
    container = ProviderContainer(
      overrides: [tokenStorageProvider.overrideWithValue(tokenStorage)],
    );
    flow = AuthFlow(
      repository: this.repository,
      credentialProvider: this.credentialProvider,
      session: container.read(authSessionProvider),
      tokenStorage: tokenStorage,
      readStatus: () => container.read(authStatusControllerProvider),
      reportError: (error, {bool blocking = false}) =>
          reported.add((error: error, blocking: blocking)),
      isSignupRequired: isSignupRequiredError,
      isStateConflict: isStateConflictError,
      isEmailAlreadyInUse: isEmailAlreadyInUseError,
      isInvalidCredentials: isInvalidCredentialsError,
      isDefinitiveSignupRejection: isDefinitiveSignupRejectionError,
    );
  }

  final FakeAuthRepository repository;
  final FakeAuthCredentialProvider credentialProvider;
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
    expect(harness.credentialProvider.calls, ['signOut']);
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

  group('Apple·Google 로그인', () {
    const signedInResult = SignInResult(tokens: _tokens, member: _member);

    DioException apiError(ErrorCode errorCode, int status) => DioException(
      requestOptions: RequestOptions(path: '/api/auth/login'),
      error: ApiException(errorCode: errorCode, httpStatus: status),
    );

    test('signInWithApple_cancelled_returnsCancelledAndKeepsState', () async {
      final harness = _Harness(
        credentialProvider: FakeAuthCredentialProvider(
          signInError: const SignInCancelledException(),
        ),
      );

      final outcome = await harness.flow.signInWithApple();

      expect(outcome, SignInOutcome.cancelled);
      expect(harness.status, AuthStatus.unknown);
      expect(harness.reported, isEmpty);
      expect(harness.repository.loginCredential, isNull);
      expect(harness.tokenStorage.savedTokens, isNull);
    });

    test('signInWithApple_success_signsInWithMember', () async {
      final harness = _Harness(
        repository: FakeAuthRepository(signInResult: signedInResult),
      );

      final outcome = await harness.flow.signInWithApple();

      expect(outcome, SignInOutcome.signedIn);
      expect(harness.repository.loginCredential, 'apple-token');
      expect(harness.status, AuthStatus.signedIn);
      expect(harness.currentMember, _member);
      expect(harness.tokenStorage.savedTokens, _tokens);
    });

    test('signInWithGoogle_success_signsInWithGoogleToken', () async {
      final harness = _Harness(
        repository: FakeAuthRepository(signInResult: signedInResult),
      );

      final outcome = await harness.flow.signInWithGoogle();

      expect(outcome, SignInOutcome.signedIn);
      expect(harness.repository.loginCredential, 'google-token');
      expect(harness.status, AuthStatus.signedIn);
    });

    test('signInWithGoogle_cancelled_returnsCancelled', () async {
      final harness = _Harness(
        credentialProvider: FakeAuthCredentialProvider(
          signInError: const SignInCancelledException(),
        ),
      );

      final outcome = await harness.flow.signInWithGoogle();

      expect(outcome, SignInOutcome.cancelled);
      expect(harness.repository.loginCount, 0);
    });

    test('authSignupRequired_returnsSignupRequiredWithoutSigningIn', () async {
      final harness = _Harness(
        repository: FakeAuthRepository(
          loginError: apiError(ErrorCode.authSignupRequired, 404),
        ),
      );

      final outcome = await harness.flow.signInWithGoogle();

      expect(outcome, SignInOutcome.signupRequired);
      expect(harness.status, AuthStatus.unknown);
      expect(harness.tokenStorage.savedTokens, isNull);
      expect(harness.reported, isEmpty);
      expect(harness.credentialProvider.calls, ['signInWithGoogle']);
    });

    test('otherLoginError_propagates', () async {
      final error = apiError(ErrorCode.authTokenInvalid, 401);
      final harness = _Harness(
        repository: FakeAuthRepository(loginError: error),
      );

      await expectLater(harness.flow.signInWithApple(), throwsA(error));

      expect(harness.status, AuthStatus.unknown);
    });
  });

  group('completeSignup_firebaseSession', () {
    const signedInResult = SignInResult(tokens: _tokens, member: _member);

    DioException apiError(ErrorCode errorCode, int status) => DioException(
      requestOptions: RequestOptions(path: '/api/auth/signup'),
      error: ApiException(errorCode: errorCode, httpStatus: status),
    );

    test('success_signsUpWithLatestTokenAndSignsIn', () async {
      final repository = FakeAuthRepository(signInResult: signedInResult);
      final harness = _Harness(repository: repository);

      await harness.flow.completeSignup(draft: _sessionDraft, nickname: '티큐');

      expect(repository.signUpRequest?.credential, 'latest-token');
      expect(repository.signUpRequest?.nickname, '티큐');
      expect(repository.signUpRequest?.serviceTermsAgreed, isTrue);
      expect(repository.signUpRequest?.privacyPolicyAgreed, isTrue);
      expect(repository.loginCount, 0);
      expect(harness.status, AuthStatus.signedIn);
      expect(harness.currentMember, _member);
      expect(harness.tokenStorage.savedTokens, _tokens);
    });

    test('stateConflict_retriesLoginOnceWithSameTokenAndSignsIn', () async {
      final repository = FakeAuthRepository(
        signInResult: signedInResult,
        signUpError: apiError(ErrorCode.stateConflict, 409),
      );
      final harness = _Harness(repository: repository);

      await harness.flow.completeSignup(draft: _sessionDraft, nickname: '티큐');

      expect(repository.loginCount, 1);
      expect(repository.loginCredential, 'latest-token');
      expect(harness.status, AuthStatus.signedIn);
      expect(harness.currentMember, _member);
    });

    test('duplicateNickname_propagatesWithoutRetry', () async {
      final error = apiError(ErrorCode.duplicateNickname, 409);
      final repository = FakeAuthRepository(
        signInResult: signedInResult,
        signUpError: error,
      );
      final harness = _Harness(repository: repository);

      await expectLater(
        harness.flow.completeSignup(draft: _sessionDraft, nickname: '티큐'),
        throwsA(error),
      );

      expect(repository.loginCount, 0);
      expect(harness.status, AuthStatus.unknown);
    });

    test('retryLoginFailure_propagates', () async {
      final retryError = apiError(ErrorCode.authTokenInvalid, 401);
      final harness = _Harness(
        repository: FakeAuthRepository(
          signUpError: apiError(ErrorCode.stateConflict, 409),
          loginError: retryError,
        ),
      );

      await expectLater(
        harness.flow.completeSignup(draft: _sessionDraft, nickname: '티큐'),
        throwsA(retryError),
      );
    });
  });

  group('signInWithEmail', () {
    const signedInResult = SignInResult(tokens: _tokens, member: _member);

    DioException apiError(ErrorCode errorCode, int status) => DioException(
      requestOptions: RequestOptions(path: '/api/auth/login'),
      error: ApiException(errorCode: errorCode, httpStatus: status),
    );

    test('success_logsInWithEmailSignInToken', () async {
      final harness = _Harness(
        repository: FakeAuthRepository(signInResult: signedInResult),
      );

      final outcome = await harness.flow.signInWithEmail(
        email: 'user@example.com',
        password: 'Abcdef12',
      );

      expect(outcome, SignInOutcome.signedIn);
      expect(harness.repository.loginCredential, 'email-sign-in-token');
      expect(harness.status, AuthStatus.signedIn);
    });

    test(
      'authSignupRequired_returnsSignupRequiredAndKeepsFirebaseSession',
      () async {
        final harness = _Harness(
          repository: FakeAuthRepository(
            loginError: apiError(ErrorCode.authSignupRequired, 404),
          ),
        );

        final outcome = await harness.flow.signInWithEmail(
          email: 'user@example.com',
          password: 'Abcdef12',
        );

        expect(outcome, SignInOutcome.signupRequired);
        expect(harness.status, AuthStatus.unknown);
        expect(harness.reported, isEmpty);
        expect(harness.credentialProvider.calls, ['signInWithEmail']);
      },
    );

    test('wrongPassword_propagatesWithoutCallingServer', () async {
      const error = InvalidCredentialsException();
      final harness = _Harness(
        credentialProvider: FakeAuthCredentialProvider(emailSignInError: error),
      );

      await expectLater(
        harness.flow.signInWithEmail(email: 'a@b.co', password: 'x'),
        throwsA(error),
      );

      expect(harness.repository.loginCount, 0);
    });
  });

  group('completeSignup_emailSignup', () {
    const signedInResult = SignInResult(tokens: _tokens, member: _member);
    const emailInUse = EmailAlreadyInUseException();

    DioException apiError(ErrorCode errorCode, int status) => DioException(
      requestOptions: RequestOptions(path: '/api/auth/signup'),
      error: ApiException(errorCode: errorCode, httpStatus: status),
    );

    test('success_checksNicknameThenCreatesAccountThenSignsUp', () async {
      final harness = _Harness(
        repository: FakeAuthRepository(signInResult: signedInResult),
      );

      final outcome = await harness.flow.completeSignup(
        draft: _emailDraft,
        nickname: '티큐',
      );

      expect(outcome, SignupOutcome.signedIn);
      expect(harness.repository.checkedNickname, '티큐');
      expect(harness.credentialProvider.calls, ['createEmailAccount']);
      expect(harness.credentialProvider.lastEmailCredentials, (
        email: 'user@example.com',
        password: 'Abcdef12',
      ));
      expect(
        harness.repository.signUpRequest?.credential,
        'email-created-token',
      );
      expect(harness.status, AuthStatus.signedIn);
      expect(harness.currentMember, _member);
    });

    test('nicknameTaken_stopsBeforeCreatingFirebaseAccount', () async {
      final harness = _Harness(
        repository: FakeAuthRepository(isNicknameAvailable: false),
      );

      final outcome = await harness.flow.completeSignup(
        draft: _emailDraft,
        nickname: '티큐',
      );

      expect(outcome, SignupOutcome.nicknameUnavailable);
      expect(harness.credentialProvider.calls, isEmpty);
      expect(harness.repository.signUpCount, 0);
      expect(harness.status, AuthStatus.unknown);
    });

    test('createFailsWithOtherError_propagatesWithoutSignUp', () async {
      const error = TooManyAttemptsException();
      final harness = _Harness(
        credentialProvider: FakeAuthCredentialProvider(
          createAccountError: error,
        ),
      );

      await expectLater(
        harness.flow.completeSignup(draft: _emailDraft, nickname: '티큐'),
        throwsA(error),
      );

      expect(harness.repository.signUpCount, 0);
    });

    test('emailInUse_signInSucceedsAndMemberExists_justLogsIn', () async {
      final harness = _Harness(
        repository: FakeAuthRepository(signInResult: signedInResult),
        credentialProvider: FakeAuthCredentialProvider(
          createAccountError: emailInUse,
        ),
      );

      final outcome = await harness.flow.completeSignup(
        draft: _emailDraft,
        nickname: '티큐',
      );

      expect(outcome, SignupOutcome.signedIn);
      expect(harness.credentialProvider.calls, [
        'createEmailAccount',
        'signInWithEmail',
      ]);
      expect(harness.repository.loginCredential, 'email-sign-in-token');
      expect(harness.repository.signUpCount, 0);
      expect(harness.status, AuthStatus.signedIn);
    });

    test(
      'emailInUse_signInSucceedsButNoMember_finishesInterruptedSignup',
      () async {
        final harness = _Harness(
          repository: FakeAuthRepository(
            signInResult: signedInResult,
            loginError: apiError(ErrorCode.authSignupRequired, 404),
          ),
          credentialProvider: FakeAuthCredentialProvider(
            createAccountError: emailInUse,
          ),
        );

        await harness.flow.completeSignup(draft: _emailDraft, nickname: '티큐');

        expect(
          harness.repository.signUpRequest?.credential,
          'email-sign-in-token',
        );
        expect(harness.repository.signUpRequest?.nickname, '티큐');
        expect(harness.status, AuthStatus.signedIn);
        // 이번 시도에서 만든 계정이 아니므로 지우지 않는다.
        expect(
          harness.credentialProvider.calls,
          isNot(contains('deleteCreatedAccount')),
        );
      },
    );

    test('emailInUse_signInFails_showsEmailAlreadyInUse', () async {
      final harness = _Harness(
        credentialProvider: FakeAuthCredentialProvider(
          createAccountError: emailInUse,
          emailSignInError: const InvalidCredentialsException(),
        ),
      );

      await expectLater(
        harness.flow.completeSignup(draft: _emailDraft, nickname: '티큐'),
        throwsA(same(emailInUse)),
      );

      expect(harness.repository.loginCount, 0);
      expect(harness.repository.signUpCount, 0);
    });

    test('emailInUse_signInFailsOnNetwork_rethrowsNetworkError', () async {
      const networkError = NetworkException(NetworkFailureKind.connection);
      final harness = _Harness(
        credentialProvider: FakeAuthCredentialProvider(
          createAccountError: emailInUse,
          emailSignInError: networkError,
        ),
      );

      // 네트워크 오류를 "이미 사용 중인 이메일"로 바꾸지 않는다.
      await expectLater(
        harness.flow.completeSignup(draft: _emailDraft, nickname: '티큐'),
        throwsA(same(networkError)),
      );

      expect(harness.repository.loginCount, 0);
      expect(harness.repository.signUpCount, 0);
    });

    test('emailInUse_recoveredSignUpRejected_doesNotDeleteAccount', () async {
      final harness = _Harness(
        repository: FakeAuthRepository(
          loginError: apiError(ErrorCode.authSignupRequired, 404),
          signUpError: apiError(ErrorCode.invalidRequest, 400),
        ),
        credentialProvider: FakeAuthCredentialProvider(
          createAccountError: emailInUse,
        ),
      );

      await expectLater(
        harness.flow.completeSignup(draft: _emailDraft, nickname: '티큐'),
        throwsA(isA<DioException>()),
      );

      expect(
        harness.credentialProvider.calls,
        isNot(contains('deleteCreatedAccount')),
      );
    });

    for (final status in [400, 401]) {
      test('definitiveRejection_${status}_deletesJustCreatedAccount', () async {
        final error = apiError(ErrorCode.invalidRequest, status);
        final harness = _Harness(
          repository: FakeAuthRepository(signUpError: error),
        );

        await expectLater(
          harness.flow.completeSignup(draft: _emailDraft, nickname: '티큐'),
          throwsA(error),
        );

        expect(harness.credentialProvider.calls, [
          'createEmailAccount',
          'deleteCreatedAccount',
        ]);
      });
    }

    test('deleteFailure_isIgnoredAndOriginalErrorPropagates', () async {
      final error = apiError(ErrorCode.authTokenInvalid, 401);
      final harness = _Harness(
        repository: FakeAuthRepository(signUpError: error),
        credentialProvider: FakeAuthCredentialProvider(
          deleteCreatedAccountError: Exception('delete failed'),
        ),
      );

      await expectLater(
        harness.flow.completeSignup(draft: _emailDraft, nickname: '티큐'),
        throwsA(error),
      );
    });

    test('stateConflict_retriesLoginWithSameTokenAndKeepsAccount', () async {
      final harness = _Harness(
        repository: FakeAuthRepository(
          signInResult: signedInResult,
          signUpError: apiError(ErrorCode.stateConflict, 409),
        ),
      );

      await harness.flow.completeSignup(draft: _emailDraft, nickname: '티큐');

      expect(harness.repository.loginCount, 1);
      expect(harness.repository.loginCredential, 'email-created-token');
      expect(harness.credentialProvider.calls, ['createEmailAccount']);
      expect(harness.status, AuthStatus.signedIn);
    });

    test('duplicateNickname_keepsAccountAndPropagates', () async {
      final error = apiError(ErrorCode.duplicateNickname, 409);
      final harness = _Harness(
        repository: FakeAuthRepository(signUpError: error),
      );

      await expectLater(
        harness.flow.completeSignup(draft: _emailDraft, nickname: '티큐'),
        throwsA(error),
      );

      expect(harness.credentialProvider.calls, ['createEmailAccount']);
    });

    test('networkAndServerErrors_neverDeleteAccount', () async {
      final errors = <Object>[
        DioException(
          requestOptions: RequestOptions(path: '/api/auth/signup'),
          type: DioExceptionType.connectionError,
        ),
        apiError(ErrorCode.internalServerError, 500),
        apiError(ErrorCode.authServerUnavailable, 502),
      ];
      for (final error in errors) {
        final harness = _Harness(
          repository: FakeAuthRepository(signUpError: error),
        );

        await expectLater(
          harness.flow.completeSignup(draft: _emailDraft, nickname: '티큐'),
          throwsA(error),
        );

        expect(harness.credentialProvider.calls, ['createEmailAccount']);
      }
    });
  });

  group('changePassword', () {
    const emailMember = Member(
      memberId: 'member-1',
      email: 'user@example.com',
      nickname: '티큐',
      hasAiCharacter: false,
      loginType: LoginType.email,
    );

    test('passesMemberEmailAndBothPasswordsToCredentialProvider', () async {
      final harness = _Harness();
      await harness.container.read(authSessionProvider).restored(emailMember);

      await harness.flow.changePassword(current: 'oldpass1', next: 'newpass12');

      expect(harness.credentialProvider.lastPasswordChange, (
        email: 'user@example.com',
        currentPassword: 'oldpass1',
        newPassword: 'newpass12',
      ));
      expect(harness.repository.deleteAccountCount, 0);
    });

    test('wrongCurrentPassword_propagates', () async {
      const error = InvalidCurrentPasswordException();
      final harness = _Harness(
        credentialProvider: FakeAuthCredentialProvider(
          changePasswordError: error,
        ),
      );
      await harness.container.read(authSessionProvider).restored(emailMember);

      await expectLater(
        harness.flow.changePassword(current: 'x', next: 'newpass12'),
        throwsA(error),
      );
    });

    test('memberWithoutEmail_throwsStateError', () async {
      final harness = _Harness();
      await harness.container.read(authSessionProvider).restored(_member);

      await expectLater(
        harness.flow.changePassword(current: 'x', next: 'newpass12'),
        throwsStateError,
      );
      expect(harness.credentialProvider.calls, isEmpty);
    });
  });

  group('sessionExpiry', () {
    test('signedInToSignedOut_signsOutOfCredentialSession', () async {
      final provider = FakeAuthCredentialProvider();
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
          authCredentialProviderProvider.overrideWithValue(provider),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
      );
      addTearDown(container.dispose);
      container.read(authFlowProvider);
      container.read(authStatusControllerProvider.notifier).markSignedIn();

      container.read(authStatusControllerProvider.notifier).markSignedOut();
      await Future<void>.delayed(Duration.zero);

      expect(provider.calls, ['signOut']);
    });

    test('unknownToSignedOut_doesNotTouchCredentialSession', () async {
      final provider = FakeAuthCredentialProvider();
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
          authCredentialProviderProvider.overrideWithValue(provider),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
      );
      addTearDown(container.dispose);
      container.read(authFlowProvider);

      container.read(authStatusControllerProvider.notifier).markSignedOut();
      await Future<void>.delayed(Duration.zero);

      expect(provider.calls, isEmpty);
    });
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

  test('deleteAccount_callsRepositoryThenSignsOut_withoutLogout', () async {
    final harness = _Harness(
      repository: FakeAuthRepository(),
      storedTokens: _tokens,
    );
    harness.container
        .read(authStatusControllerProvider.notifier)
        .markSignedIn();

    await harness.flow.deleteAccount();

    expect(harness.repository.deleteAccountCount, 1);
    expect(harness.repository.logoutCount, 0);
    expect(harness.status, AuthStatus.signedOut);
    expect(harness.tokenStorage.storedTokens, isNull);
  });

  test('deleteAccount_runsBeforeSigningOutBeforeSignOut', () async {
    final harness = _Harness(storedTokens: _tokens);
    harness.container
        .read(authStatusControllerProvider.notifier)
        .markSignedIn();
    AuthStatus? statusInsideCallback;

    await harness.flow.deleteAccount(
      beforeSigningOut: () => statusInsideCallback = harness.status,
    );

    expect(statusInsideCallback, AuthStatus.signedIn);
    expect(harness.status, AuthStatus.signedOut);
  });

  test('deleteAccount_failure_propagatesAndKeepsSession', () async {
    final error = Exception('server down');
    final harness = _Harness(
      repository: FakeAuthRepository(deleteAccountError: error),
      storedTokens: _tokens,
    );
    harness.container
        .read(authStatusControllerProvider.notifier)
        .markSignedIn();
    var callbackCalled = false;

    await expectLater(
      harness.flow.deleteAccount(beforeSigningOut: () => callbackCalled = true),
      throwsA(error),
    );

    expect(callbackCalled, isFalse);
    expect(harness.status, AuthStatus.signedIn);
    expect(harness.tokenStorage.storedTokens, _tokens);
  });

  test('logout_signsOutOfCredentialSessionAndIgnoresItsFailure', () async {
    final harness = _Harness(
      credentialProvider: FakeAuthCredentialProvider(
        signOutError: Exception('firebase down'),
      ),
      storedTokens: _tokens,
    );
    harness.container
        .read(authStatusControllerProvider.notifier)
        .markSignedIn();

    await harness.flow.logout();

    expect(harness.credentialProvider.calls, ['signOut']);
    expect(harness.status, AuthStatus.signedOut);
    expect(harness.tokenStorage.storedTokens, isNull);
  });

  group('deleteAccount_credentialProvider', () {
    const googleMember = Member(
      memberId: 'member-1',
      nickname: '티큐',
      hasAiCharacter: false,
      loginType: LoginType.google,
    );

    test(
      'apple_revokesThenDeletesAccountThenSignsOut_withoutDeletingFirebaseUser',
      () async {
        final provider = FakeAuthCredentialProvider();
        final harness = _Harness(
          repository: FakeAuthRepository(
            onDeleteAccount: () => provider.calls.add('deleteAccount'),
          ),
          credentialProvider: provider,
          storedTokens: _tokens,
        );
        await harness.container.read(authSessionProvider).restored(_member);

        final isDeleted = await harness.flow.deleteAccount();

        expect(isDeleted, isTrue);
        expect(provider.calls, [
          'revokeAppleConnection',
          'deleteAccount',
          'signOut',
        ]);
        expect(harness.status, AuthStatus.signedOut);
        expect(harness.tokenStorage.storedTokens, isNull);
      },
    );

    test('apple_reauthenticationCancelled_staysSignedInSilently', () async {
      final provider = FakeAuthCredentialProvider(
        revokeError: const SignInCancelledException(),
      );
      final harness = _Harness(
        credentialProvider: provider,
        storedTokens: _tokens,
      );
      await harness.container.read(authSessionProvider).restored(_member);
      var callbackCalled = false;

      final isDeleted = await harness.flow.deleteAccount(
        beforeSigningOut: () => callbackCalled = true,
      );

      expect(isDeleted, isFalse);
      expect(callbackCalled, isFalse);
      expect(harness.repository.deleteAccountCount, 0);
      expect(provider.calls, ['revokeAppleConnection']);
      expect(harness.status, AuthStatus.signedIn);
      expect(harness.tokenStorage.storedTokens, _tokens);
    });

    test('apple_revokeFailure_abortsWithoutDeletingAnything', () async {
      const failure = AppleConnectionRevokeFailedException('revoke 실패');
      final provider = FakeAuthCredentialProvider(revokeError: failure);
      final harness = _Harness(
        credentialProvider: provider,
        storedTokens: _tokens,
      );
      await harness.container.read(authSessionProvider).restored(_member);

      await expectLater(harness.flow.deleteAccount(), throwsA(failure));

      expect(failure.userMessage, 'Apple 연동을 해제하지 못했어요. 잠시 후 다시 시도해 주세요.');
      expect(harness.repository.deleteAccountCount, 0);
      expect(provider.calls, ['revokeAppleConnection']);
      expect(harness.currentMember, _member);
      expect(harness.tokenStorage.storedTokens, _tokens);
    });

    test('apple_serverDeleteFailure_keepsSession', () async {
      final error = Exception('server down');
      final provider = FakeAuthCredentialProvider();
      final harness = _Harness(
        repository: FakeAuthRepository(deleteAccountError: error),
        credentialProvider: provider,
        storedTokens: _tokens,
      );
      await harness.container.read(authSessionProvider).restored(_member);

      await expectLater(harness.flow.deleteAccount(), throwsA(error));

      expect(provider.calls, ['revokeAppleConnection']);
      expect(harness.currentMember, _member);
    });

    test('google_skipsRevokeAndOnlySignsOutOfCredentialSession', () async {
      final provider = FakeAuthCredentialProvider();
      final harness = _Harness(
        repository: FakeAuthRepository(
          onDeleteAccount: () => provider.calls.add('deleteAccount'),
        ),
        credentialProvider: provider,
        storedTokens: _tokens,
      );
      await harness.container.read(authSessionProvider).restored(googleMember);

      final isDeleted = await harness.flow.deleteAccount();

      expect(isDeleted, isTrue);
      expect(provider.calls, ['deleteAccount', 'signOut']);
      expect(harness.status, AuthStatus.signedOut);
    });

    test('credentialSignOutFailure_isIgnored', () async {
      final provider = FakeAuthCredentialProvider(
        signOutError: Exception('firebase down'),
      );
      final harness = _Harness(
        credentialProvider: provider,
        storedTokens: _tokens,
      );
      await harness.container.read(authSessionProvider).restored(googleMember);

      final isDeleted = await harness.flow.deleteAccount();

      expect(isDeleted, isTrue);
      expect(harness.status, AuthStatus.signedOut);
      expect(harness.tokenStorage.storedTokens, isNull);
    });
  });

  test('refreshMember_replacesCurrentMemberWithFetchedMember', () async {
    const fetched = Member(
      memberId: 'member-1',
      nickname: '티큐',
      hasAiCharacter: false,
      loginType: LoginType.apple,
      email: 'user@example.com',
    );
    final harness = _Harness(repository: FakeAuthRepository(member: fetched));
    await harness.container.read(authSessionProvider).restored(_member);

    await harness.flow.refreshMember();

    expect(harness.currentMember?.email, 'user@example.com');
  });

  group('refreshMember_stale', () {
    const fetched = Member(
      memberId: 'member-1',
      nickname: '티큐',
      hasAiCharacter: false,
      loginType: LoginType.apple,
      email: 'user@example.com',
    );

    Future<_Harness> signedInHarness(FakeAuthRepository repository) async {
      final harness = _Harness(repository: repository);
      await harness.container.read(authSessionProvider).restored(_member);
      return harness;
    }

    test('logoutWhileFetching_doesNotRestoreMember', () async {
      final repository = FakeAuthRepository(member: fetched)
        ..fetchMeGate = Completer<void>();
      final harness = await signedInHarness(repository);

      final refreshing = harness.flow.refreshMember();
      await harness.flow.logout();
      repository.fetchMeGate!.complete();
      await refreshing;

      expect(harness.status, AuthStatus.signedOut);
      expect(harness.currentMember, isNull);
    });

    test('differentMemberSignedInWhileFetching_ignoresResult', () async {
      final repository = FakeAuthRepository(member: fetched)
        ..fetchMeGate = Completer<void>();
      final harness = await signedInHarness(repository);
      const otherMember = Member(
        memberId: 'member-2',
        nickname: '다른사람',
        hasAiCharacter: false,
        loginType: LoginType.google,
      );

      final refreshing = harness.flow.refreshMember();
      await harness.flow.logout();
      await harness.container.read(authSessionProvider).restored(otherMember);
      repository.fetchMeGate!.complete();
      await refreshing;

      expect(harness.currentMember, otherMember);
    });

    test('failureAfterLogout_isSwallowed', () async {
      final repository = FakeAuthRepository(
        member: fetched,
        fetchMeError: Exception('late failure'),
      )..fetchMeGate = Completer<void>();
      final harness = await signedInHarness(repository);

      final refreshing = harness.flow.refreshMember();
      await harness.flow.logout();
      repository.fetchMeGate!.complete();

      await expectLater(refreshing, completes);
    });

    test('failureWhileStillCurrent_propagates', () async {
      final error = Exception('failure');
      final harness = await signedInHarness(
        FakeAuthRepository(member: fetched, fetchMeError: error),
      );

      await expectLater(harness.flow.refreshMember(), throwsA(error));
    });
  });

  group('changeNickname', () {
    const emailMember = Member(
      memberId: 'member-1',
      email: 'user@example.com',
      nickname: '티큐',
      hasAiCharacter: false,
      loginType: LoginType.google,
    );
    final renamed = emailMember.copyWith(nickname: '새닉네임');

    Future<_Harness> signedInHarness(FakeAuthRepository repository) async {
      final harness = _Harness(repository: repository);
      await harness.container.read(authSessionProvider).restored(emailMember);
      return harness;
    }

    test('updatesCurrentMemberNickname', () async {
      final repository = FakeAuthRepository(member: renamed);
      final harness = await signedInHarness(repository);

      await harness.flow.changeNickname('새닉네임');

      expect(repository.changedNickname, '새닉네임');
      expect(harness.currentMember?.nickname, '새닉네임');
    });

    test('logoutWhileWaiting_doesNotRestoreMember', () async {
      final repository = FakeAuthRepository(member: renamed)
        ..changeNicknameGate = Completer<void>();
      final harness = await signedInHarness(repository);

      final changing = harness.flow.changeNickname('새닉네임');
      await harness.flow.logout();
      repository.changeNicknameGate!.complete();
      await changing;

      expect(harness.status, AuthStatus.signedOut);
      expect(harness.currentMember, isNull);
    });

    test('serverError_propagatesAndKeepsMember', () async {
      final error = Exception('duplicate');
      final harness = await signedInHarness(
        FakeAuthRepository(member: renamed, changeNicknameError: error),
      );

      await expectLater(harness.flow.changeNickname('새닉네임'), throwsA(error));

      expect(harness.currentMember, emailMember);
    });
  });

  group('replaceProfileImage', () {
    final image = ProfileImageFile(
      fileName: 'photo.png',
      bytes: Uint8List.fromList([1, 2, 3]),
    );
    final withImage = _member.copyWith(
      profileImageUrl: 'https://cdn.example.com/profile.png',
    );

    test('updatesProfileImageUrl', () async {
      final repository = FakeAuthRepository(member: withImage);
      final harness = _Harness(repository: repository);
      await harness.container.read(authSessionProvider).restored(_member);

      await harness.flow.replaceProfileImage(image);

      expect(repository.replacedProfileImage, image);
      expect(
        harness.currentMember?.profileImageUrl,
        'https://cdn.example.com/profile.png',
      );
    });

    test('logoutWhileWaiting_doesNotRestoreMember', () async {
      final repository = FakeAuthRepository(member: withImage)
        ..replaceProfileImageGate = Completer<void>();
      final harness = _Harness(repository: repository);
      await harness.container.read(authSessionProvider).restored(_member);

      final replacing = harness.flow.replaceProfileImage(image);
      await harness.flow.logout();
      repository.replaceProfileImageGate!.complete();
      await replacing;

      expect(harness.currentMember, isNull);
    });

    test('serverError_propagatesAndKeepsMember', () async {
      final error = Exception('invalid image');
      final harness = _Harness(
        repository: FakeAuthRepository(
          member: withImage,
          replaceProfileImageError: error,
        ),
      );
      await harness.container.read(authSessionProvider).restored(_member);

      await expectLater(
        harness.flow.replaceProfileImage(image),
        throwsA(error),
      );

      expect(harness.currentMember, _member);
    });
  });
}
