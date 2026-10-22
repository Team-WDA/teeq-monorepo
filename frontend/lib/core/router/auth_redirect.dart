import 'package:teeq/core/auth/auth_status.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/router/app_routes.dart';

/// 로그인 상태, 회원, 현재 위치로 리다이렉트할 위치를 정한다. 이동이 필요 없으면 null.
/// 로그인 상태인데 회원이 아직 없으면 가입 완료 회원이며 캐릭터가 있는 회원과 같게 다룬다.
/// 가입이 끝나지 않은 회원은 약관 화면(`/signup-completion`)과, 그 화면이 push하는 닉네임 화면에서만 머물 수 있고
/// 나머지 위치에서는 약관 화면으로 보낸다.
/// 가입을 마쳤지만 캐릭터가 없는 회원은 `/onboarding/**` 밖의 모든 위치에서 온보딩으로 보낸다.
/// 스플래시 최소 노출 시간이 지나기 전에는 로그인 상태와 무관하게 `/splash`에 머문다.
/// 복원이 더 오래 걸려 이미 지난 뒤라면 영향이 없다.
/// 앱 업데이트가 필요하면(`/error` 제외) 로그인 상태와 무관하게 `/update-required`에만 머문다.
String? authRedirect(
  AuthStatus status,
  Member? member,
  String location, {
  required bool isSplashMinimumDisplayElapsed,
  required bool isUpdateRequired,
}) {
  if (location == AppRoutes.error) {
    return null;
  }
  if (isUpdateRequired) {
    return location == AppRoutes.updateRequired
        ? null
        : AppRoutes.updateRequired;
  }
  if (location == AppRoutes.splash && !isSplashMinimumDisplayElapsed) {
    return null;
  }
  switch (status) {
    case AuthStatus.unknown:
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    case AuthStatus.signedOut:
      return _signedOutLocations.contains(location) ? null : AppRoutes.welcome;
    case AuthStatus.signedIn:
      if (member != null && !member.isSignupCompleted) {
        return _signupCompletionLocations.contains(location)
            ? null
            : AppRoutes.signupCompletion;
      }
      if (member != null && !member.hasAiCharacter) {
        return _isOnboardingLocation(location) ? null : AppRoutes.onboarding;
      }
      // 캐릭터가 있는 회원은 시작 화면만 막고, 수정 흐름이 쓰는 나머지 온보딩 하위 위치는 허용한다.
      return location == AppRoutes.onboarding ||
              _signedInEntryLocations.contains(location)
          ? AppRoutes.home
          : null;
  }
}

bool _isOnboardingLocation(String location) =>
    location == AppRoutes.onboarding ||
    location.startsWith('${AppRoutes.onboarding}/');

/// 로그아웃 상태에서 머물 수 있는 위치.
const _signedOutLocations = {
  AppRoutes.welcome,
  AppRoutes.login,
  AppRoutes.signup,
  AppRoutes.signupNickname,
};

/// 가입이 끝나지 않은 로그인 회원이 머물 수 있는 위치.
/// 닉네임 화면은 약관 화면에서 push되며, go_router 18은 push된 위치에도 리다이렉트를 평가하므로 허용해야 한다.
const _signupCompletionLocations = {
  AppRoutes.signupCompletion,
  AppRoutes.signupNickname,
};

/// 로그인한 완료 회원이 머물 필요가 없어 홈으로 보내는 진입 위치.
/// 캐릭터가 없는 회원은 이 위치에서도 홈이 아니라 온보딩으로 보낸다.
/// 닉네임 화면은 push된 라우트라 go_router 18에서 기준 위치가 가입 시작 화면(`/welcome`)으로 유지된다.
/// 그래서 가입 성공으로 로그인 상태가 바뀌면 리다이렉트가 `/welcome` 기준으로 평가되어 홈으로 보낸다.
/// 온보딩 도착은 닉네임 화면이 가입 직후(다음 프레임 전, 아직 마운트된 상태) 호출하는
/// `context.go(AppRoutes.onboarding)`에 의존한다. 이 흐름은 signup_to_onboarding_flow_test가 지킨다.
const _signedInEntryLocations = {
  AppRoutes.splash,
  AppRoutes.welcome,
  AppRoutes.login,
  AppRoutes.signup,
  AppRoutes.signupCompletion,
};
