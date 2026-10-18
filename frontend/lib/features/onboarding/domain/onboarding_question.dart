import 'package:teeq/features/onboarding/domain/onboarding_option.dart';

/// 온보딩 질문 7개. 선언 순서와 [code]는 BE `OnboardingQuestion`과 같다.
enum OnboardingQuestion {
  relationship(
    code: 'RELATIONSHIP',
    title: '우리,\n어떤 사이로 지낼까?',
    description: '너에게 가장 편안한 관계를 골라줘.',
  ),
  personality(
    code: 'PERSONALITY',
    title: '너는 어떤\n성격이 좋아?',
    description: '마음에 드는 성격을 골라줘.',
  ),
  speechStyle(
    code: 'SPEECH_STYLE',
    title: '어떤 말투가\n제일 좋아?',
    description: '같은 말도 어떻게 하느냐가 중요하니까.',
  ),
  voiceTone(
    code: 'VOICE_TONE',
    title: '어떤 목소리로\n들려줄까?',
    description: '오래 들어도 편안한 목소리를 골라줘.',
  ),
  adviceStyle(
    code: 'ADVICE_STYLE',
    title: '고민 상담할 때,\nT가 좋아? F가 좋아?',
    description: '네가 속상한 일을 털어놓는다면?',
  ),
  conversationLead(
    code: 'CONVERSATION_LEAD',
    title: '대화할 땐\n누가 리드하는 게 좋아?',
    description: '우리의 대화 텐션을 맞춰보자.',
  ),
  avoidBehavior(
    code: 'AVOID_BEHAVIOR',
    title: '대화할 때,\n이것만은 피했으면 해!',
    description: '불편하게 느껴지는 대화 방식을 알려줘.',
    maxSelections: 5,
  );

  const OnboardingQuestion({
    required this.code,
    required this.title,
    required this.description,
    this.maxSelections = 1,
  });

  /// BE enum 이름과 같은 질문 코드.
  final String code;
  final String title;

  /// 제목 아래 부제(선택 방식 표기 제외).
  final String description;

  /// 모든 질문이 최소 1개를 골라야 답한 것으로 본다.
  final int minSelections = 1;
  final int maxSelections;

  bool get isMultipleChoice => maxSelections > 1;

  /// 이 질문에 속한 선택지(선언 순서).
  List<OnboardingOption> get options => OnboardingOption.values
      .where((option) => option.question == this)
      .toList(growable: false);
}
