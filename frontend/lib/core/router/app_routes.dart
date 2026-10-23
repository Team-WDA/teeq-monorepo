/// 라우트 경로 상수.
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String signupNickname = '/signup/nickname';
  static const String signupCompletion = '/signup-completion';
  static const String onboarding = '/onboarding';
  static const String onboardingQuestions = '/onboarding/questions';
  static const String onboardingGenerating = '/onboarding/generating';
  static const String characterName = '/onboarding/character-name';
  static const String characterResult = '/onboarding/character-result';
  static const String home = '/';
  static const String myPage = '/my-page';
  static const String nicknameChange = '/my-page/nickname';
  static const String serviceTerms = '/my-page/service-terms';
  static const String privacyPolicy = '/my-page/privacy-policy';
  static const String bugReport = '/my-page/bug-report';
  static const String error = '/error';
  static const String updateRequired = '/update-required';
  static const String feedbackClosing = '/calls/:callSessionId/feedback';
  static const String feedbackCompletion =
      '/calls/:callSessionId/feedback/completion';
  static const String detailedFeedback =
      '/calls/:callSessionId/feedback/detail';
  static const String detailedFeedbackCompletion =
      '/calls/:callSessionId/feedback/detail/completion';

  static String feedbackClosingLocation(String callSessionId) =>
      '/calls/${Uri.encodeComponent(callSessionId)}/feedback';

  static String feedbackCompletionLocation(String callSessionId) =>
      '${feedbackClosingLocation(callSessionId)}/completion';

  static String detailedFeedbackLocation(String callSessionId) =>
      '${feedbackClosingLocation(callSessionId)}/detail';

  static String detailedFeedbackCompletionLocation(String callSessionId) =>
      '${detailedFeedbackLocation(callSessionId)}/completion';
}
