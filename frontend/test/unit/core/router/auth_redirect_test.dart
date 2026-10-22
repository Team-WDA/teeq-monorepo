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
          expect(
            authRedirect(
              status,
              member,
              AppRoutes.error,
              isSplashMinimumDisplayElapsed: true,
            ),
            isNull,
          );
        }
      }
    });

    test('unknown은 splash로, 이미 splash면 null', () {
      expect(
        authRedirect(
          AuthStatus.unknown,
          null,
          AppRoutes.home,
          isSplashMinimumDisplayElapsed: true,
        ),
        AppRoutes.splash,
      );
      expect(
        authRedirect(
          AuthStatus.unknown,
          null,
          AppRoutes.login,
          isSplashMinimumDisplayElapsed: true,
        ),
        AppRoutes.splash,
      );
      expect(
        authRedirect(
          AuthStatus.unknown,
          null,
          AppRoutes.splash,
          isSplashMinimumDisplayElapsed: true,
        ),
        isNull,
      );
    });

    test('signedOut은 welcome으로 보내고 허용 위치에서는 null', () {
      for (final location in [
        AppRoutes.home,
        AppRoutes.splash,
        AppRoutes.signupCompletion,
        AppRoutes.onboarding,
      ]) {
        expect(
          authRedirect(
            AuthStatus.signedOut,
            null,
            location,
            isSplashMinimumDisplayElapsed: true,
          ),
          AppRoutes.welcome,
        );
      }
      for (final location in [
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.signup,
        AppRoutes.signupNickname,
      ]) {
        expect(
          authRedirect(
            AuthStatus.signedOut,
            null,
            location,
            isSplashMinimumDisplayElapsed: true,
          ),
          isNull,
        );
      }
    });

    test('signedIn + 미완료 회원은 signupCompletion으로, 이미 거기면 null', () {
      for (final location in [
        AppRoutes.splash,
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.signup,
        AppRoutes.onboarding,
        AppRoutes.home,
      ]) {
        expect(
          authRedirect(
            AuthStatus.signedIn,
            _incompleteMember,
            location,
            isSplashMinimumDisplayElapsed: true,
          ),
          AppRoutes.signupCompletion,
        );
      }
      expect(
        authRedirect(
          AuthStatus.signedIn,
          _incompleteMember,
          AppRoutes.signupCompletion,
          isSplashMinimumDisplayElapsed: true,
        ),
        isNull,
      );
    });

    test('signedIn + 미완료 회원은 약관 화면이 push하는 닉네임 위치에서 null', () {
      expect(
        authRedirect(
          AuthStatus.signedIn,
          _incompleteMember,
          AppRoutes.signupNickname,
          isSplashMinimumDisplayElapsed: true,
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
          authRedirect(
            AuthStatus.signedIn,
            _memberWithoutCharacter,
            location,
            isSplashMinimumDisplayElapsed: true,
          ),
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
          authRedirect(
            AuthStatus.signedIn,
            _memberWithoutCharacter,
            location,
            isSplashMinimumDisplayElapsed: true,
          ),
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
          isSplashMinimumDisplayElapsed: true,
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
          authRedirect(
            AuthStatus.signedIn,
            _memberWithCharacter,
            location,
            isSplashMinimumDisplayElapsed: true,
          ),
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
          authRedirect(
            AuthStatus.signedIn,
            _memberWithCharacter,
            location,
            isSplashMinimumDisplayElapsed: true,
          ),
          AppRoutes.home,
        );
      }
      for (final location in [AppRoutes.signupNickname, AppRoutes.home]) {
        expect(
          authRedirect(
            AuthStatus.signedIn,
            _memberWithCharacter,
            location,
            isSplashMinimumDisplayElapsed: true,
          ),
          isNull,
        );
      }
    });

    test('null member behaves like member with character', () {
      expect(
        authRedirect(
          AuthStatus.signedIn,
          null,
          AppRoutes.onboarding,
          isSplashMinimumDisplayElapsed: true,
        ),
        AppRoutes.home,
      );
      expect(
        authRedirect(
          AuthStatus.signedIn,
          null,
          AppRoutes.characterResult,
          isSplashMinimumDisplayElapsed: true,
        ),
        isNull,
      );
    });

    group('최소 노출 시간 전', () {
      const members = [
        null,
        _memberWithoutCharacter,
        _memberWithCharacter,
        _incompleteMember,
      ];

      test('splash는 모든 상태에서 null', () {
        for (final status in AuthStatus.values) {
          for (final member in members) {
            expect(
              authRedirect(
                status,
                member,
                AppRoutes.splash,
                isSplashMinimumDisplayElapsed: false,
              ),
              isNull,
            );
          }
        }
      });

      test('error 위치는 붙잡지 않고 null', () {
        for (final status in AuthStatus.values) {
          for (final member in members) {
            expect(
              authRedirect(
                status,
                member,
                AppRoutes.error,
                isSplashMinimumDisplayElapsed: false,
              ),
              isNull,
            );
          }
        }
      });

      test('unknown이 splash가 아닌 위치에 있으면 splash로 보낸다', () {
        for (final location in [AppRoutes.home, AppRoutes.login]) {
          expect(
            authRedirect(
              AuthStatus.unknown,
              null,
              location,
              isSplashMinimumDisplayElapsed: false,
            ),
            AppRoutes.splash,
          );
        }
      });

      test('splash가 아닌 위치에서는 기존 분기를 따른다', () {
        expect(
          authRedirect(
            AuthStatus.signedOut,
            null,
            AppRoutes.home,
            isSplashMinimumDisplayElapsed: false,
          ),
          AppRoutes.welcome,
        );
        expect(
          authRedirect(
            AuthStatus.signedIn,
            _memberWithCharacter,
            AppRoutes.onboarding,
            isSplashMinimumDisplayElapsed: false,
          ),
          AppRoutes.home,
        );
      });
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
          authRedirect(
            AuthStatus.signedIn,
            null,
            location,
            isSplashMinimumDisplayElapsed: true,
          ),
          AppRoutes.home,
        );
      }
      expect(
        authRedirect(
          AuthStatus.signedIn,
          null,
          AppRoutes.home,
          isSplashMinimumDisplayElapsed: true,
        ),
        isNull,
      );
    });
  });
}
