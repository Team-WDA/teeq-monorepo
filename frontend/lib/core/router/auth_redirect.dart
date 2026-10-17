import 'package:teeq/core/auth/auth_status.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/router/app_routes.dart';

/// 로그인 상태, 회원, 현재 위치로 리다이렉트할 위치를 정한다. 이동이 필요 없으면 null.
/// 로그인 상태인데 회원이 아직 없으면 가입 완료 회원과 같게 다룬다.
String? authRedirect(AuthStatus status, Member? member, String location) {
  if (location == AppRoutes.error) {
    return null;
  }
  switch (status) {
    case AuthStatus.unknown:
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    case AuthStatus.signedOut:
      return location == AppRoutes.login ? null : AppRoutes.login;
    case AuthStatus.signedIn:
      if (member != null && !member.isSignupCompleted) {
        return location == AppRoutes.signupCompletion
            ? null
            : AppRoutes.signupCompletion;
      }
      final isEntryLocation =
          location == AppRoutes.splash ||
          location == AppRoutes.login ||
          location == AppRoutes.signupCompletion;
      return isEntryLocation ? AppRoutes.home : null;
  }
}
