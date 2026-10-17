import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/auth/auth_status.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/router/auth_redirect.dart';

void main() {
  group('authRedirect', () {
    test('error 위치는 어떤 상태에서도 null', () {
      for (final status in AuthStatus.values) {
        expect(authRedirect(status, AppRoutes.error), isNull);
      }
    });

    test('unknown은 splash로, 이미 splash면 null', () {
      expect(
        authRedirect(AuthStatus.unknown, AppRoutes.home),
        AppRoutes.splash,
      );
      expect(
        authRedirect(AuthStatus.unknown, AppRoutes.login),
        AppRoutes.splash,
      );
      expect(authRedirect(AuthStatus.unknown, AppRoutes.splash), isNull);
    });

    test('signedOut은 login으로, 이미 login이면 null', () {
      expect(
        authRedirect(AuthStatus.signedOut, AppRoutes.home),
        AppRoutes.login,
      );
      expect(
        authRedirect(AuthStatus.signedOut, AppRoutes.splash),
        AppRoutes.login,
      );
      expect(authRedirect(AuthStatus.signedOut, AppRoutes.login), isNull);
    });

    test('signedIn은 splash/login에서 home으로, 그 외 null', () {
      expect(
        authRedirect(AuthStatus.signedIn, AppRoutes.splash),
        AppRoutes.home,
      );
      expect(
        authRedirect(AuthStatus.signedIn, AppRoutes.login),
        AppRoutes.home,
      );
      expect(authRedirect(AuthStatus.signedIn, AppRoutes.home), isNull);
    });
  });
}
