import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/auth/auth_status.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/router/auth_redirect.dart';

const _memberWithoutCharacter = Member(
  memberId: 'member-1',
  nickname: '티큐',
  hasAiCharacter: false,
  loginType: LoginType.apple,
);

const _memberWithCharacter = Member(
  memberId: 'member-3',
  nickname: '티큐',
  hasAiCharacter: true,
  loginType: LoginType.apple,
);

const _incompleteMember = Member(
  memberId: 'member-2',
  hasAiCharacter: false,
  loginType: LoginType.apple,
);

void main() {
  group('authRedirect', () {
    test('error 위치는 어떤 상태에서도 null', () {
      for (final status in AuthStatus.values) {
        for (final member in [
          null,
          _memberWithoutCharacter,
          _memberWithCharacter,
          _incompleteMember,
        ]) {
          expect(authRedirect(status, member, AppRoutes.error), isNull);
        }
      }
    });

    test('unknown은 splash로, 이미 splash면 null', () {
      expect(
        authRedirect(AuthStatus.unknown, null, AppRoutes.home),
        AppRoutes.splash,
      );
      expect(
        authRedirect(AuthStatus.unknown, null, AppRoutes.login),
        AppRoutes.splash,
      );
      expect(authRedirect(AuthStatus.unknown, null, AppRoutes.splash), isNull);
    });

    test('signedOut은 welcome으로 보내고 허용 위치에서는 null', () {
      for (final location in [
        AppRoutes.home,
        AppRoutes.splash,
        AppRoutes.signupCompletion,
        AppRoutes.onboarding,
      ]) {
        expect(
          authRedirect(AuthStatus.signedOut, null, location),
          AppRoutes.welcome,
        );
      }
      for (final location in [
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.signup,
        AppRoutes.signupNickname,
      ]) {
        expect(authRedirect(AuthStatus.signedOut, null, location), isNull);
      }
    });

    test('signedIn + 미완료 회원은 signupCompletion으로, 이미 거기면 null', () {
      for (final location in [
        AppRoutes.splash,
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.signup,
        AppRoutes.signupNickname,
        AppRoutes.onboarding,
        AppRoutes.home,
      ]) {
        expect(
          authRedirect(AuthStatus.signedIn, _incompleteMember, location),
          AppRoutes.signupCompletion,
        );
      }
      expect(
        authRedirect(
          AuthStatus.signedIn,
          _incompleteMember,
          AppRoutes.signupCompletion,
        ),
        isNull,
      );
    });

    test('completed member without character is sent to onboarding from every non-onboarding location', () {
      for (final location in [
        AppRoutes.splash,
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.signup,
        AppRoutes.signupNickname,
        AppRoutes.signupCompletion,
        AppRoutes.home,
      ]) {
        expect(
          authRedirect(AuthStatus.signedIn, _memberWithoutCharacter, location),
          AppRoutes.onboarding,
        );
      }
    });

    test('without character stays on onboarding and its subroutes', () {
      for (final location in [
        AppRoutes.onboarding,
        AppRoutes.onboardingQuestions,
        AppRoutes.onboardingGenerating,
        AppRoutes.characterName,
        AppRoutes.characterResult,
      ]) {
        expect(
          authRedirect(AuthStatus.signedIn, _memberWithoutCharacter, location),
          isNull,
        );
      }
    });

    test('with character on onboarding intro goes home', () {
      expect(
        authRedirect(
          AuthStatus.signedIn,
          _memberWithCharacter,
          AppRoutes.onboarding,
        ),
        AppRoutes.home,
      );
    });

    test('with character allows onboarding subroutes', () {
      for (final location in [
        AppRoutes.onboardingQuestions,
        AppRoutes.onboardingGenerating,
        AppRoutes.characterName,
        AppRoutes.characterResult,
      ]) {
        expect(
          authRedirect(AuthStatus.signedIn, _memberWithCharacter, location),
          isNull,
        );
      }
    });

    test('with character on entry locations goes home', () {
      for (final location in [
        AppRoutes.splash,
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.signup,
        AppRoutes.signupCompletion,
      ]) {
        expect(
          authRedirect(AuthStatus.signedIn, _memberWithCharacter, location),
          AppRoutes.home,
        );
      }
      for (final location in [AppRoutes.signupNickname, AppRoutes.home]) {
        expect(
          authRedirect(AuthStatus.signedIn, _memberWithCharacter, location),
          isNull,
        );
      }
    });

    test('null member behaves like member with character', () {
      expect(
        authRedirect(AuthStatus.signedIn, null, AppRoutes.onboarding),
        AppRoutes.home,
      );
      expect(
        authRedirect(AuthStatus.signedIn, null, AppRoutes.characterResult),
        isNull,
      );
    });

    test('signedIn + 회원 null은 완료와 같게 다룬다', () {
      for (final location in [
        AppRoutes.splash,
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.signup,
        AppRoutes.signupCompletion,
      ]) {
        expect(
          authRedirect(AuthStatus.signedIn, null, location),
          AppRoutes.home,
        );
      }
      expect(authRedirect(AuthStatus.signedIn, null, AppRoutes.home), isNull);
    });
  });
}
