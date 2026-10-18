import 'package:teeq/core/auth/auth_status.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/router/app_routes.dart';

/// 로그인 상태, 회원, 현재 위치로 리다이렉트할 위치를 정한다. 이동이 필요 없으면 null.
/// 로그인 상태인데 회원이 아직 없으면 가입 완료 회원이며 캐릭터가 있는 회원과 같게 다룬다.
/// 가입을 마쳤지만 캐릭터가 없는 회원은 `/onboarding/**` 밖의 모든 위치에서 온보딩으로 보낸다.
String? authRedirect(AuthStatus status, Member? member, String location) {
  if (location == AppRoutes.error) {
    return null;
  }
  switch (status) {
    case AuthStatus.unknown:
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    case AuthStatus.signedOut:
      return _signedOutLocations.contains(location) ? null : AppRoutes.welcome;
    case AuthStatus.signedIn:
      if (member != null && !member.isSignupCompleted) {
        return location == AppRoutes.signupCompletion
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
