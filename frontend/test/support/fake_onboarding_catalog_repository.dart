import 'dart:async';

import 'package:teeq/features/onboarding/domain/onboarding_catalog.dart';
import 'package:teeq/features/onboarding/domain/onboarding_catalog_repository.dart';
import 'package:teeq/features/onboarding/domain/onboarding_copy.dart';
import 'package:teeq/features/onboarding/domain/onboarding_option.dart';
import 'package:teeq/features/onboarding/domain/onboarding_question.dart';

/// 서버 질문 구조(질문 코드, 최대 선택 수, 선택지 코드)를 BE 선언 순서대로 적은 표.
const _questionStructures = <(String, int, List<String>)>[
  (
    'RELATIONSHIP',
    1,
    [
      'RELATIONSHIP_CLOSE_FRIEND',
      'RELATIONSHIP_RELIABLE_FRIEND',
      'RELATIONSHIP_SWEET_PARTNER',
      'RELATIONSHIP_LIFE_MENTOR',
    ],
  ),
  (
    'PERSONALITY',
    1,
    [
      'PERSONALITY_MOOD_MAKER',
      'PERSONALITY_PLAYFUL_JOKER',
      'PERSONALITY_CALM_WARM',
      'PERSONALITY_FREE_SPIRIT',
    ],
  ),
  (
    'SPEECH_STYLE',
    1,
    [
      'SPEECH_STYLE_CLOSE_FRIEND_CASUAL',
      'SPEECH_STYLE_AFFECTIONATE_CASUAL',
      'SPEECH_STYLE_GENTLE_POLITE',
    ],
  ),
  (
    'VOICE_TONE',
    1,
    [
      'VOICE_TONE_HIGH_BRIGHT',
      'VOICE_TONE_MID_NATURAL',
      'VOICE_TONE_MID_LOW_CALM',
      'VOICE_TONE_LOW_DEEP',
    ],
  ),
  (
    'ADVICE_STYLE',
    1,
    [
      'ADVICE_STYLE_EMPATHY_ONLY',
      'ADVICE_STYLE_REALISTIC_ADVICE_ONLY',
      'ADVICE_STYLE_TAKE_MY_SIDE',
      'ADVICE_STYLE_BALANCED',
    ],
  ),
  (
    'CONVERSATION_LEAD',
    1,
    [
      'CONVERSATION_LEAD_LISTENER',
      'CONVERSATION_LEAD_BALANCED',
      'CONVERSATION_LEAD_LEADER',
    ],
  ),
  (
    'AVOID_BEHAVIOR',
    5,
    [
      'AVOID_BEHAVIOR_RAPID_QUESTIONS',
      'AVOID_BEHAVIOR_UNASKED_ADVICE',
      'AVOID_BEHAVIOR_EXCESSIVE_POSITIVITY',
      'AVOID_BEHAVIOR_REPEATED_RESPONSES',
      'AVOID_BEHAVIOR_INTERRUPTING',
    ],
  ),
];

/// 테스트용 7개 질문 카탈로그. 문구는 실제 [OnboardingCopy]에서 가져온다.
final OnboardingCatalog testOnboardingCatalog = OnboardingCatalog([
  for (final (questionCode, maxSelections, optionCodes) in _questionStructures)
    OnboardingQuestion(
      code: questionCode,
      title: OnboardingCopy.questions[questionCode]!.title,
      description: OnboardingCopy.questions[questionCode]!.description,
      minSelections: 1,
      maxSelections: maxSelections,
      options: [
        for (final optionCode in optionCodes)
          OnboardingOption(
            code: optionCode,
            label: OnboardingCopy.optionLabels[optionCode]!,
          ),
      ],
    ),
]);

/// [testOnboardingCatalog]에서 [code] 질문을 찾는다.
OnboardingQuestion testOnboardingQuestion(String code) => testOnboardingCatalog
    .questions
    .firstWhere((question) => question.code == code);

/// [testOnboardingCatalog]에서 [code] 선택지를 찾는다.
OnboardingOption testOnboardingOption(String code) => testOnboardingCatalog
    .questions
    .expand((question) => question.options)
    .firstWhere((option) => option.code == code);

/// 호출 횟수를 기록하고 미리 정한 카탈로그 또는 오류를 돌려주는 테스트용 저장소.
class FakeOnboardingCatalogRepository implements OnboardingCatalogRepository {
  FakeOnboardingCatalogRepository({
    OnboardingCatalog? catalog,
    this.firstFetchError,
    this.gate,
  }) : catalog = catalog ?? testOnboardingCatalog;

  final OnboardingCatalog catalog;

  /// 지정하면 첫 호출만 이 오류를 던지고 이후 호출은 성공한다(재시도 재현용).
  final Object? firstFetchError;

  /// 지정하면 [fetchCatalog]가 이 게이트가 완료될 때까지 기다린다(응답 지연 재현용).
  final Completer<void>? gate;

  int fetchCount = 0;

  @override
  Future<OnboardingCatalog> fetchCatalog() async {
    fetchCount += 1;
    await gate?.future;
    final error = firstFetchError;
    if (error != null && fetchCount == 1) {
      throw error;
    }
    return catalog;
  }
}
