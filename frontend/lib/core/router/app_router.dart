import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/auth/auth_status_controller.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/router/auth_redirect.dart';
import 'package:teeq/core/router/error_page_arguments.dart';
import 'package:teeq/core/ui/layout/main_tab_shell_screen.dart';
import 'package:teeq/features/auth/presentation/email_login_screen.dart';
import 'package:teeq/features/auth/presentation/email_signup_credentials_screen.dart';
import 'package:teeq/features/auth/presentation/signup_completion_screen.dart';
import 'package:teeq/features/auth/presentation/signup_nickname_screen.dart';
import 'package:teeq/features/auth/presentation/welcome_screen.dart';
import 'package:teeq/features/error/presentation/error_screen.dart';
import 'package:teeq/features/feedback/presentation/feedback_flow_controller.dart';
import 'package:teeq/features/feedback/presentation/feedback_flow_redirect.dart';
import 'package:teeq/features/feedback/presentation/screens/call_closing_screen.dart';
import 'package:teeq/features/feedback/presentation/screens/detailed_feedback_completion_screen.dart';
import 'package:teeq/features/feedback/presentation/screens/detailed_feedback_screen.dart';
import 'package:teeq/features/feedback/presentation/screens/feedback_completion_screen.dart';
import 'package:teeq/features/home/presentation/home_screen.dart';
import 'package:teeq/features/my_page/domain/legal_document.dart';
import 'package:teeq/features/my_page/presentation/legal_document_screen.dart';
import 'package:teeq/features/my_page/presentation/my_page_screen.dart';
import 'package:teeq/features/my_page/presentation/nickname_change_screen.dart';
import 'package:teeq/features/my_page/presentation/password_change_completion_screen.dart';
import 'package:teeq/features/my_page/presentation/password_change_screen.dart';
import 'package:teeq/features/onboarding/presentation/character_generating_screen.dart';
import 'package:teeq/features/onboarding/presentation/character_name_screen.dart';
import 'package:teeq/features/onboarding/presentation/character_result_screen.dart';
import 'package:teeq/features/onboarding/presentation/character_setup_flow_controller.dart';
import 'package:teeq/features/onboarding/presentation/onboarding_introduction_screen.dart';
import 'package:teeq/features/onboarding/presentation/onboarding_question_screen.dart';
import 'package:teeq/features/splash/presentation/splash_screen.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // 로그인 상태나 회원이 바뀌면 리다이렉트를 다시 평가하도록 알린다.
  final refreshNotifier = ValueNotifier<int>(0);
  ref.listen(authStatusControllerProvider, (previous, next) {
    refreshNotifier.value++;
  });
  ref.listen(currentMemberControllerProvider, (previous, next) {
    refreshNotifier.value++;
  });

  // 흐름 상태 없이 이름·결과 화면에 들어오면 캐릭터 보유 여부에 따라 시작 화면이나 홈으로 보낸다.
  String redirectWithoutGeneratedCharacter() =>
      ref.read(currentMemberControllerProvider)?.hasAiCharacter == true
      ? AppRoutes.home
      : AppRoutes.onboarding;

  // 선행 단계를 마치지 않았거나 다른 통화의 흐름이면 홈으로 보낸다.
  String? redirectFeedbackFlow(GoRouterState state, FeedbackFlowStep step) =>
      feedbackFlowRedirect(
        ref.read(feedbackFlowControllerProvider),
        state.pathParameters['callSessionId']!,
        step,
      );

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: refreshNotifier,
    redirect: (context, state) => authRedirect(
      ref.read(authStatusControllerProvider),
      ref.read(currentMemberControllerProvider),
      state.uri.path,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const EmailLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const EmailSignupCredentialsScreen(),
      ),
      GoRoute(
        path: AppRoutes.signupNickname,
        builder: (context, state) => const SignupNicknameScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingIntroductionScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingQuestions,
        builder: (context, state) => const OnboardingQuestionScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingGenerating,
        redirect: (context, state) =>
            ref.read(characterSetupFlowControllerProvider).selections.isComplete
            ? null
            : AppRoutes.onboardingQuestions,
        builder: (context, state) => const CharacterGeneratingScreen(),
      ),
      GoRoute(
        path: AppRoutes.characterName,
        redirect: (context, state) =>
            ref.read(characterSetupFlowControllerProvider).character == null
            ? redirectWithoutGeneratedCharacter()
            : null,
        builder: (context, state) => const CharacterNameScreen(),
      ),
      GoRoute(
        path: AppRoutes.characterResult,
        redirect: (context, state) =>
            ref.read(characterSetupFlowControllerProvider).character?.name ==
                null
            ? redirectWithoutGeneratedCharacter()
            : null,
        builder: (context, state) => const CharacterResultScreen(),
      ),
      GoRoute(
        path: AppRoutes.signupCompletion,
        builder: (context, state) => const SignupCompletionScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainTabShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.myPage,
                builder: (context, state) => const MyPageScreen(),
              ),
            ],
          ),
        ],
      ),
      // 탭 바 없이 뒤로 가기 헤더만 있는 화면이라 셸 밖에 둔다.
      GoRoute(
        path: AppRoutes.nicknameChange,
        builder: (context, state) => const NicknameChangeScreen(),
      ),
      GoRoute(
        path: AppRoutes.passwordChange,
        builder: (context, state) => const PasswordChangeScreen(),
      ),
      GoRoute(
        path: AppRoutes.passwordChangeCompletion,
        builder: (context, state) => const PasswordChangeCompletionScreen(),
      ),
      GoRoute(
        path: AppRoutes.serviceTerms,
        builder: (context, state) =>
            const LegalDocumentScreen(type: LegalDocumentType.serviceTerms),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (context, state) =>
            const LegalDocumentScreen(type: LegalDocumentType.privacyPolicy),
      ),
      GoRoute(
        path: AppRoutes.feedbackClosing,
        builder: (context, state) => CallClosingScreen(
          callSessionId: state.pathParameters['callSessionId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.feedbackCompletion,
        redirect: (context, state) =>
            redirectFeedbackFlow(state, FeedbackFlowStep.completion),
        builder: (context, state) => FeedbackCompletionScreen(
          callSessionId: state.pathParameters['callSessionId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.detailedFeedback,
        redirect: (context, state) =>
            redirectFeedbackFlow(state, FeedbackFlowStep.detailedFeedback),
        builder: (context, state) => DetailedFeedbackScreen(
          callSessionId: state.pathParameters['callSessionId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.detailedFeedbackCompletion,
        redirect: (context, state) =>
            redirectFeedbackFlow(state, FeedbackFlowStep.detailedCompletion),
        builder: (context, state) => DetailedFeedbackCompletionScreen(
          callSessionId: state.pathParameters['callSessionId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.error,
        builder: (context, state) =>
            ErrorScreen(arguments: state.extra as ErrorPageArguments?),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refreshNotifier.dispose();
  });
  return router;
}
