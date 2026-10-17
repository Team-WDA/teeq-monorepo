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

import '../../../support/fake_token_storage.dart';

const _tokens = AuthTokens(accessToken: 'access', refreshToken: 'refresh');
const _member = Member(
  memberId: 'member-1',
  nickname: '티큐',
  hasAiCharacter: false,
  loginType: LoginType.apple,
);

ProviderContainer _container(FakeTokenStorage storage) {
  final container = ProviderContainer(
    overrides: [tokenStorageProvider.overrideWithValue(storage)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('signIn_savesTokensAndMemberAndMarksSignedIn', () async {
    final storage = FakeTokenStorage();
    final container = _container(storage);

    await container
        .read(authSessionProvider)
        .signIn(const SignInResult(tokens: _tokens, member: _member));

    expect(storage.savedTokens, _tokens);
    expect(container.read(currentMemberControllerProvider), _member);
    expect(container.read(authStatusControllerProvider), AuthStatus.signedIn);
  });

  test('restored_keepsMemberAndMarksSignedInWithoutSavingTokens', () async {
    final storage = FakeTokenStorage(storedTokens: _tokens);
    final container = _container(storage);

    await container.read(authSessionProvider).restored(_member);

    expect(storage.savedTokens, isNull);
    expect(container.read(currentMemberControllerProvider), _member);
    expect(container.read(authStatusControllerProvider), AuthStatus.signedIn);
  });

  test('signOut_clearsTokensMemberAndMarksSignedOut', () async {
    final storage = FakeTokenStorage();
    final container = _container(storage);
    final session = container.read(authSessionProvider);
    await session.signIn(const SignInResult(tokens: _tokens, member: _member));

    await session.signOut();

    expect(storage.storedTokens, isNull);
    expect(container.read(currentMemberControllerProvider), isNull);
    expect(container.read(authStatusControllerProvider), AuthStatus.signedOut);
  });

  test('signOut_whenStorageClearThrows_stillMarksSignedOut', () async {
    final storage = FakeTokenStorage(clearError: StateError('clear 실패'));
    final container = _container(storage);
    final session = container.read(authSessionProvider);
    await session.signIn(const SignInResult(tokens: _tokens, member: _member));

    await expectLater(session.signOut(), throwsStateError);

    expect(container.read(authStatusControllerProvider), AuthStatus.signedOut);
    expect(container.read(currentMemberControllerProvider), isNull);
  });
}
