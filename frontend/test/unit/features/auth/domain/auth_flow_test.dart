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
import 'package:teeq/features/auth/domain/auth_flow.dart';
import 'package:teeq/features/auth/domain/profile_image_file.dart';
import 'package:teeq/features/auth/domain/social_credential_provider.dart';
import 'package:teeq/features/auth/presentation/auth_flow_provider.dart';

import '../../../../support/fake_auth_repository.dart';
import '../../../../support/fake_social_credential_provider.dart';
import '../../../../support/fake_token_storage.dart';

const _tokens = AuthTokens(accessToken: 'access', refreshToken: 'refresh');

const _member = Member(
  memberId: 'member-1',
  nickname: '티큐',
  hasAiCharacter: false,
  loginType: LoginType.apple,
);

class _Harness {
  _Harness({
    FakeAuthRepository? repository,
    FakeSocialCredentialProvider? socialProvider,
    AuthTokens? storedTokens,
  }) : repository = repository ?? FakeAuthRepository(),
       socialProvider = socialProvider ?? FakeSocialCredentialProvider(),
       tokenStorage = FakeTokenStorage(storedTokens: storedTokens) {
    container = ProviderContainer(
      overrides: [tokenStorageProvider.overrideWithValue(tokenStorage)],
    );
    flow = AuthFlow(
      repository: this.repository,
      socialCredentialProvider: this.socialProvider,
      session: container.read(authSessionProvider),
      tokenStorage: tokenStorage,
      readStatus: () => container.read(authStatusControllerProvider),
      reportError: (error, {bool blocking = false}) =>
          reported.add((error: error, blocking: blocking)),
      isSignupRequired: isSocialSignupRequiredError,
      isStateConflict: isStateConflictError,
    );
  }

  final FakeAuthRepository repository;
  final FakeSocialCredentialProvider socialProvider;
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

  group('소셜 로그인', () {
    const signedInResult = SignInResult(tokens: _tokens, member: _member);

    DioException apiError(ErrorCode errorCode, int status) => DioException(
      requestOptions: RequestOptions(path: '/api/auth/social-login'),
      error: ApiException(errorCode: errorCode, httpStatus: status),
    );

    test('signInWithApple_cancelled_returnsCancelledAndKeepsState', () async {
      final harness = _Harness(
        socialProvider: FakeSocialCredentialProvider(
          signInError: const SocialSignInCancelledException(),
        ),
      );

      final outcome = await harness.flow.signInWithApple();

      expect(outcome, SocialSignInOutcome.cancelled);
      expect(harness.status, AuthStatus.unknown);
      expect(harness.reported, isEmpty);
      expect(harness.repository.socialLoginCredential, isNull);
      expect(harness.tokenStorage.savedTokens, isNull);
    });

    test('signInWithApple_success_signsInWithMember', () async {
      final harness = _Harness(
        repository: FakeAuthRepository(signInResult: signedInResult),
      );

      final outcome = await harness.flow.signInWithApple();

      expect(outcome, SocialSignInOutcome.signedIn);
      expect(harness.repository.socialLoginCredential, 'apple-token');
      expect(harness.status, AuthStatus.signedIn);
      expect(harness.currentMember, _member);
      expect(harness.tokenStorage.savedTokens, _tokens);
    });

    test('signInWithGoogle_success_signsInWithGoogleToken', () async {
      final harness = _Harness(
        repository: FakeAuthRepository(signInResult: signedInResult),
      );

      final outcome = await harness.flow.signInWithGoogle();

      expect(outcome, SocialSignInOutcome.signedIn);
      expect(harness.repository.socialLoginCredential, 'google-token');
      expect(harness.status, AuthStatus.signedIn);
    });

    test('signInWithGoogle_cancelled_returnsCancelled', () async {
      final harness = _Harness(
        socialProvider: FakeSocialCredentialProvider(
          signInError: const SocialSignInCancelledException(),
        ),
      );

      final outcome = await harness.flow.signInWithGoogle();

      expect(outcome, SocialSignInOutcome.cancelled);
      expect(harness.repository.socialLoginCount, 0);
    });

    test(
      'socialSignupRequired_returnsSignupRequiredWithoutSigningIn',
      () async {
        final harness = _Harness(
          repository: FakeAuthRepository(
            socialLoginError: apiError(ErrorCode.socialSignupRequired, 404),
          ),
        );

        final outcome = await harness.flow.signInWithGoogle();

        expect(outcome, SocialSignInOutcome.signupRequired);
        expect(harness.status, AuthStatus.unknown);
        expect(harness.tokenStorage.savedTokens, isNull);
        expect(harness.reported, isEmpty);
        expect(harness.socialProvider.calls, ['signInWithGoogle']);
      },
    );

    test('otherLoginError_propagates', () async {
      final error = apiError(ErrorCode.socialTokenInvalid, 401);
      final harness = _Harness(
        repository: FakeAuthRepository(socialLoginError: error),
      );

      await expectLater(harness.flow.signInWithApple(), throwsA(error));

      expect(harness.status, AuthStatus.unknown);
    });
  });

  group('completeSocialSignup', () {
    const signedInResult = SignInResult(tokens: _tokens, member: _member);

    DioException apiError(ErrorCode errorCode, int status) => DioException(
      requestOptions: RequestOptions(path: '/api/auth/social-signup'),
      error: ApiException(errorCode: errorCode, httpStatus: status),
    );

    test('success_signsUpWithLatestTokenAndSignsIn', () async {
      final repository = FakeAuthRepository(signInResult: signedInResult);
      final harness = _Harness(repository: repository);

      await harness.flow.completeSocialSignup(
        nickname: '티큐',
        serviceTermsAgreed: true,
        privacyPolicyAgreed: true,
      );

      expect(repository.socialSignUpRequest?.credential, 'latest-token');
      expect(repository.socialSignUpRequest?.nickname, '티큐');
      expect(repository.socialSignUpRequest?.serviceTermsAgreed, isTrue);
      expect(repository.socialSignUpRequest?.privacyPolicyAgreed, isTrue);
      expect(repository.socialLoginCount, 0);
      expect(harness.status, AuthStatus.signedIn);
      expect(harness.currentMember, _member);
      expect(harness.tokenStorage.savedTokens, _tokens);
    });

    test(
      'stateConflict_retriesSocialLoginOnceWithSameTokenAndSignsIn',
      () async {
        final repository = FakeAuthRepository(
          signInResult: signedInResult,
          socialSignUpError: apiError(ErrorCode.stateConflict, 409),
        );
        final harness = _Harness(repository: repository);

        await harness.flow.completeSocialSignup(
          nickname: '티큐',
          serviceTermsAgreed: true,
          privacyPolicyAgreed: true,
        );

        expect(repository.socialLoginCount, 1);
        expect(repository.socialLoginCredential, 'latest-token');
        expect(harness.status, AuthStatus.signedIn);
        expect(harness.currentMember, _member);
      },
    );

    test('duplicateNickname_propagatesWithoutRetry', () async {
      final error = apiError(ErrorCode.duplicateNickname, 409);
      final repository = FakeAuthRepository(
        signInResult: signedInResult,
        socialSignUpError: error,
      );
      final harness = _Harness(repository: repository);

      await expectLater(
        harness.flow.completeSocialSignup(
          nickname: '티큐',
          serviceTermsAgreed: true,
          privacyPolicyAgreed: true,
        ),
        throwsA(error),
      );

      expect(repository.socialLoginCount, 0);
      expect(harness.status, AuthStatus.unknown);
    });

    test('retryLoginFailure_propagates', () async {
      final retryError = apiError(ErrorCode.socialTokenInvalid, 401);
      final harness = _Harness(
        repository: FakeAuthRepository(
          socialSignUpError: apiError(ErrorCode.stateConflict, 409),
          socialLoginError: retryError,
        ),
      );

      await expectLater(
        harness.flow.completeSocialSignup(
          nickname: '티큐',
          serviceTermsAgreed: true,
          privacyPolicyAgreed: true,
        ),
        throwsA(retryError),
      );
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

  test('logout_signsOutOfSocialSessionAndIgnoresItsFailure', () async {
    final harness = _Harness(
      socialProvider: FakeSocialCredentialProvider(
        signOutError: Exception('firebase down'),
      ),
      storedTokens: _tokens,
    );
    harness.container
        .read(authStatusControllerProvider.notifier)
        .markSignedIn();

    await harness.flow.logout();

    expect(harness.socialProvider.calls, ['signOut']);
    expect(harness.status, AuthStatus.signedOut);
    expect(harness.tokenStorage.storedTokens, isNull);
  });

  group('deleteAccount_social', () {
    const googleMember = Member(
      memberId: 'member-1',
      nickname: '티큐',
      hasAiCharacter: false,
      loginType: LoginType.google,
    );

    test(
      'apple_revokesThenDeletesAccountThenFirebaseUserThenSignsOut',
      () async {
        final provider = FakeSocialCredentialProvider();
        final harness = _Harness(
          repository: FakeAuthRepository(
            onDeleteAccount: () => provider.calls.add('deleteAccount'),
          ),
          socialProvider: provider,
          storedTokens: _tokens,
        );
        await harness.container.read(authSessionProvider).restored(_member);

        final isDeleted = await harness.flow.deleteAccount();

        expect(isDeleted, isTrue);
        expect(provider.calls, [
          'revokeAppleConnection',
          'deleteAccount',
          'deleteFirebaseUser',
          'signOut',
        ]);
        expect(harness.status, AuthStatus.signedOut);
        expect(harness.tokenStorage.storedTokens, isNull);
      },
    );

    test('apple_reauthenticationCancelled_staysSignedInSilently', () async {
      final provider = FakeSocialCredentialProvider(
        revokeError: const SocialSignInCancelledException(),
      );
      final harness = _Harness(socialProvider: provider, storedTokens: _tokens);
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
      final provider = FakeSocialCredentialProvider(revokeError: failure);
      final harness = _Harness(socialProvider: provider, storedTokens: _tokens);
      await harness.container.read(authSessionProvider).restored(_member);

      await expectLater(harness.flow.deleteAccount(), throwsA(failure));

      expect(failure.userMessage, 'Apple 연동을 해제하지 못했어요. 잠시 후 다시 시도해 주세요.');
      expect(harness.repository.deleteAccountCount, 0);
      expect(provider.calls, ['revokeAppleConnection']);
      expect(harness.currentMember, _member);
      expect(harness.tokenStorage.storedTokens, _tokens);
    });

    test('apple_serverDeleteFailure_keepsSessionAndFirebaseUser', () async {
      final error = Exception('server down');
      final provider = FakeSocialCredentialProvider();
      final harness = _Harness(
        repository: FakeAuthRepository(deleteAccountError: error),
        socialProvider: provider,
        storedTokens: _tokens,
      );
      await harness.container.read(authSessionProvider).restored(_member);

      await expectLater(harness.flow.deleteAccount(), throwsA(error));

      expect(provider.calls, ['revokeAppleConnection']);
      expect(harness.currentMember, _member);
    });

    test('google_skipsRevokeAndDeletesFirebaseUserAfterAccount', () async {
      final provider = FakeSocialCredentialProvider();
      final harness = _Harness(
        repository: FakeAuthRepository(
          onDeleteAccount: () => provider.calls.add('deleteAccount'),
        ),
        socialProvider: provider,
        storedTokens: _tokens,
      );
      await harness.container.read(authSessionProvider).restored(googleMember);

      final isDeleted = await harness.flow.deleteAccount();

      expect(isDeleted, isTrue);
      expect(provider.calls, [
        'deleteAccount',
        'deleteFirebaseUser',
        'signOut',
      ]);
      expect(harness.status, AuthStatus.signedOut);
    });

    test('firebaseCleanupFailures_areIgnored', () async {
      final provider = FakeSocialCredentialProvider(
        deleteFirebaseUserError: Exception('requires-recent-login'),
        signOutError: Exception('firebase down'),
      );
      final harness = _Harness(socialProvider: provider, storedTokens: _tokens);
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
