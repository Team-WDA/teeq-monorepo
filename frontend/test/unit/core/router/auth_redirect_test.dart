import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/auth/auth_status.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/router/auth_redirect.dart';

const _completedMember = Member(
  memberId: 'member-1',
  nickname: '티큐',
  hasAiCharacter: false,
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
        for (final member in [null, _completedMember, _incompleteMember]) {
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

    test('signedOut은 login으로, 이미 login이면 null', () {
      expect(
        authRedirect(AuthStatus.signedOut, null, AppRoutes.home),
        AppRoutes.login,
      );
      expect(
        authRedirect(AuthStatus.signedOut, null, AppRoutes.splash),
        AppRoutes.login,
      );
      expect(
        authRedirect(AuthStatus.signedOut, null, AppRoutes.signupCompletion),
        AppRoutes.login,
      );
      expect(authRedirect(AuthStatus.signedOut, null, AppRoutes.login), isNull);
    });

    test('signedIn + 미완료 회원은 signupCompletion으로, 이미 거기면 null', () {
      for (final location in [
        AppRoutes.splash,
        AppRoutes.login,
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

    test('signedIn + 완료 회원은 진입 위치에서 home으로, 그 외 null', () {
      for (final location in [
        AppRoutes.splash,
        AppRoutes.login,
        AppRoutes.signupCompletion,
      ]) {
        expect(
          authRedirect(AuthStatus.signedIn, _completedMember, location),
          AppRoutes.home,
        );
      }
      expect(
        authRedirect(AuthStatus.signedIn, _completedMember, AppRoutes.home),
        isNull,
      );
    });

    test('signedIn + 회원 null은 완료와 같게 다룬다', () {
      for (final location in [
        AppRoutes.splash,
        AppRoutes.login,
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
