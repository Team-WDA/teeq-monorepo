import 'package:teeq/features/onboarding/domain/onboarding_question.dart';

/// 서버 질문 구조와 FE 문구를 합친 온보딩 질문 목록(서버 응답 순서).
final class OnboardingCatalog {
  const OnboardingCatalog(this.questions);

  final List<OnboardingQuestion> questions;
}
