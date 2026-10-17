import 'package:teeq/core/auth/auth_status.dart';
import 'package:teeq/core/router/app_routes.dart';

/// 로그인 상태와 현재 위치로 리다이렉트할 위치를 정한다. 이동이 필요 없으면 null.
String? authRedirect(AuthStatus status, String location) {
  if (location == AppRoutes.error) {
    return null;
  }
  switch (status) {
    case AuthStatus.unknown:
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    case AuthStatus.signedOut:
      return location == AppRoutes.login ? null : AppRoutes.login;
    case AuthStatus.signedIn:
      final isEntryLocation =
          location == AppRoutes.splash || location == AppRoutes.login;
      return isEntryLocation ? AppRoutes.home : null;
  }
}
