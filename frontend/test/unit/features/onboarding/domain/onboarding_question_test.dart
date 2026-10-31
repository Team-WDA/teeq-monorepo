import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/features/onboarding/domain/onboarding_copy.dart';
import 'package:teeq/features/onboarding/domain/onboarding_option.dart';
import 'package:teeq/features/onboarding/domain/onboarding_question.dart';

import '../../../../support/fake_onboarding_catalog_repository.dart';

void main() {
  test('isMultipleChoice_onlyWhenMaxSelectionsAboveOne', () {
    for (final question in testOnboardingCatalog.questions) {
      expect(
        question.isMultipleChoice,
        question.code == 'AVOID_BEHAVIOR',
        reason: question.code,
      );
    }
  });

  test('equality_isBasedOnCode', () {
    const first = OnboardingQuestion(
      code: 'RELATIONSHIP',
      title: '제목',
      description: '부제',
      minSelections: 1,
      maxSelections: 1,
      options: [],
    );
    const sameCode = OnboardingQuestion(
      code: 'RELATIONSHIP',
      title: '다른 제목',
      description: '다른 부제',
      minSelections: 1,
      maxSelections: 3,
      options: [OnboardingOption(code: 'RELATIONSHIP_CLOSE_FRIEND', label: '')],
    );

    expect(first, sameCode);
    expect(first.hashCode, sameCode.hashCode);
    expect(
      const OnboardingOption(code: 'A', label: '가'),
      const OnboardingOption(code: 'A', label: '나'),
    );
    expect(
      const OnboardingOption(code: 'A', label: '가') ==
          const OnboardingOption(code: 'B', label: '가'),
      isFalse,
    );
  });

  test('copy_coversAllQuestionsAndOptions', () {
    expect(OnboardingCopy.questions.keys, [
      'RELATIONSHIP',
      'PERSONALITY',
      'SPEECH_STYLE',
      'VOICE_TONE',
      'ADVICE_STYLE',
      'CONVERSATION_LEAD',
      'AVOID_BEHAVIOR',
    ]);
    expect(OnboardingCopy.optionLabels, hasLength(27));
    expect(OnboardingCopy.questions['RELATIONSHIP']!.title, '우리,\n어떤 사이로 지낼까?');
    expect(
      OnboardingCopy.optionLabels['AVOID_BEHAVIOR_INTERRUPTING'],
      '내 말을 중간에 끊는 것',
    );
  });
}
