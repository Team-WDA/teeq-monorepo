import 'package:teeq/features/onboarding/domain/onboarding_option.dart';

/// 온보딩 질문. 구조(선택 수, 선택지 순서)는 서버 응답을 따르고 [code]가 같음 비교의 기준이다.
final class OnboardingQuestion {
  const OnboardingQuestion({
    required this.code,
    required this.title,
    required this.description,
    required this.minSelections,
    required this.maxSelections,
    required this.options,
  });

  /// BE enum 이름과 같은 질문 코드.
  final String code;
  final String title;

  /// 제목 아래 부제(선택 방식 표기 제외).
  final String description;
  final int minSelections;
  final int maxSelections;

  /// 이 질문에 속한 선택지(서버 응답 순서).
  final List<OnboardingOption> options;

  bool get isMultipleChoice => maxSelections > 1;

  @override
  bool operator ==(Object other) =>
      other is OnboardingQuestion && other.code == code;

  @override
  int get hashCode => code.hashCode;
}
