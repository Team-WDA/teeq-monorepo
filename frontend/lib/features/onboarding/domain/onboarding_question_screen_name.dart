/// 한 화면에서 질문이 바뀌므로 GA4 화면 이름을 질문 번호로 나눈다.
///
/// [questionIndex]는 0부터 시작하고 이름의 번호는 1부터 시작한다.
/// 라우트 경로 형식(선행 `/`)을 화면 전환 observer와 맞춘다.
String onboardingQuestionScreenName(int questionIndex) {
  return '/onboarding/question-${questionIndex + 1}';
}
