import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/features/onboarding/domain/onboarding_option.dart';
import 'package:teeq/features/onboarding/domain/onboarding_question.dart';

const _expectedOptionCodes = <String, List<String>>{
  'RELATIONSHIP': [
    'RELATIONSHIP_CLOSE_FRIEND',
    'RELATIONSHIP_RELIABLE_FRIEND',
    'RELATIONSHIP_SWEET_PARTNER',
    'RELATIONSHIP_LIFE_MENTOR',
  ],
  'PERSONALITY': [
    'PERSONALITY_MOOD_MAKER',
    'PERSONALITY_PLAYFUL_JOKER',
    'PERSONALITY_CALM_WARM',
    'PERSONALITY_FREE_SPIRIT',
  ],
  'SPEECH_STYLE': [
    'SPEECH_STYLE_CLOSE_FRIEND_CASUAL',
    'SPEECH_STYLE_AFFECTIONATE_CASUAL',
    'SPEECH_STYLE_GENTLE_POLITE',
  ],
  'VOICE_TONE': [
    'VOICE_TONE_HIGH_BRIGHT',
    'VOICE_TONE_MID_NATURAL',
    'VOICE_TONE_MID_LOW_CALM',
    'VOICE_TONE_LOW_DEEP',
  ],
  'ADVICE_STYLE': [
    'ADVICE_STYLE_EMPATHY_ONLY',
    'ADVICE_STYLE_REALISTIC_ADVICE_ONLY',
    'ADVICE_STYLE_TAKE_MY_SIDE',
    'ADVICE_STYLE_BALANCED',
  ],
  'CONVERSATION_LEAD': [
    'CONVERSATION_LEAD_LISTENER',
    'CONVERSATION_LEAD_BALANCED',
    'CONVERSATION_LEAD_LEADER',
  ],
  'AVOID_BEHAVIOR': [
    'AVOID_BEHAVIOR_RAPID_QUESTIONS',
    'AVOID_BEHAVIOR_UNASKED_ADVICE',
    'AVOID_BEHAVIOR_EXCESSIVE_POSITIVITY',
    'AVOID_BEHAVIOR_REPEATED_RESPONSES',
    'AVOID_BEHAVIOR_INTERRUPTING',
  ],
};

void main() {
  test('questions_followBackendDeclarationOrder', () {
    expect(OnboardingQuestion.values.map((question) => question.code), [
      'RELATIONSHIP',
      'PERSONALITY',
      'SPEECH_STYLE',
      'VOICE_TONE',
      'ADVICE_STYLE',
      'CONVERSATION_LEAD',
      'AVOID_BEHAVIOR',
    ]);
  });

  test('onlyAvoidBehavior_isMultipleChoiceWithOneToFive', () {
    for (final question in OnboardingQuestion.values) {
      if (question == OnboardingQuestion.avoidBehavior) {
        expect(question.isMultipleChoice, isTrue);
        expect(question.minSelections, 1);
        expect(question.maxSelections, 5);
      } else {
        expect(question.isMultipleChoice, isFalse);
        expect(question.minSelections, 1);
        expect(question.maxSelections, 1);
      }
    }
  });

  test('options_countPerQuestion', () {
    expect(
      OnboardingQuestion.values.map((question) => question.options.length),
      [4, 4, 3, 4, 4, 3, 5],
    );
  });

  test('optionCodes_matchSpecificationTableInOrder', () {
    for (final question in OnboardingQuestion.values) {
      expect(
        question.options.map((option) => option.code).toList(),
        _expectedOptionCodes[question.code],
        reason: question.code,
      );
    }
    expect(OnboardingOption.values, hasLength(27));
  });
}
