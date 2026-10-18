import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/features/onboarding/domain/onboarding_option.dart';
import 'package:teeq/features/onboarding/domain/onboarding_question.dart';
import 'package:teeq/features/onboarding/domain/onboarding_selections.dart';

OnboardingSelections _answerAll() {
  var selections = const OnboardingSelections.empty();
  for (final question in OnboardingQuestion.values) {
    selections = selections.toggle(question.options.first);
  }
  return selections;
}

void main() {
  test('toggle_singleChoice_replacesPreviousSelection', () {
    final selections = const OnboardingSelections.empty()
        .toggle(OnboardingOption.relationshipCloseFriend)
        .toggle(OnboardingOption.relationshipLifeMentor);

    expect(selections.selectedFor(OnboardingQuestion.relationship), {
      OnboardingOption.relationshipLifeMentor,
    });
  });

  test('toggle_singleChoice_sameOptionTwice_keepsSelection', () {
    final selections = const OnboardingSelections.empty()
        .toggle(OnboardingOption.relationshipCloseFriend)
        .toggle(OnboardingOption.relationshipCloseFriend);

    expect(selections.selectedFor(OnboardingQuestion.relationship), {
      OnboardingOption.relationshipCloseFriend,
    });
  });

  test('toggle_multipleChoice_addsAndRemoves', () {
    var selections = const OnboardingSelections.empty()
        .toggle(OnboardingOption.avoidBehaviorRapidQuestions)
        .toggle(OnboardingOption.avoidBehaviorInterrupting);
    expect(selections.selectedFor(OnboardingQuestion.avoidBehavior), {
      OnboardingOption.avoidBehaviorRapidQuestions,
      OnboardingOption.avoidBehaviorInterrupting,
    });

    selections = selections.toggle(
      OnboardingOption.avoidBehaviorRapidQuestions,
    );
    expect(selections.selectedFor(OnboardingQuestion.avoidBehavior), {
      OnboardingOption.avoidBehaviorInterrupting,
    });
  });

  test('toggle_multipleChoice_allFiveOptionsSelectable', () {
    var selections = const OnboardingSelections.empty();
    for (final option in OnboardingQuestion.avoidBehavior.options) {
      selections = selections.toggle(option);
    }

    expect(
      selections.selectedFor(OnboardingQuestion.avoidBehavior),
      OnboardingQuestion.avoidBehavior.options.toSet(),
    );
  });

  test('isAnswered_multipleChoice_zeroSelected_false', () {
    final selections = const OnboardingSelections.empty()
        .toggle(OnboardingOption.avoidBehaviorRapidQuestions)
        .toggle(OnboardingOption.avoidBehaviorRapidQuestions);

    expect(selections.isAnswered(OnboardingQuestion.avoidBehavior), isFalse);
  });

  test('isComplete_onlyWhenAllSevenAnswered', () {
    expect(const OnboardingSelections.empty().isComplete, isFalse);
    expect(_answerAll().isComplete, isTrue);

    final withoutLast = _answerAll().toggle(
      OnboardingOption.avoidBehaviorRapidQuestions,
    );
    expect(withoutLast.isComplete, isFalse);
  });

  test('toggle_returnsNewInstance_doesNotMutate', () {
    const original = OnboardingSelections.empty();
    final toggled = original.toggle(OnboardingOption.relationshipCloseFriend);

    expect(identical(original, toggled), isFalse);
    expect(original.selectedFor(OnboardingQuestion.relationship), isEmpty);
  });

  test('equality_isValueBased', () {
    final first = const OnboardingSelections.empty().toggle(
      OnboardingOption.relationshipCloseFriend,
    );
    final second = const OnboardingSelections.empty().toggle(
      OnboardingOption.relationshipCloseFriend,
    );

    expect(first, second);
    expect(first.hashCode, second.hashCode);
    expect(first == const OnboardingSelections.empty(), isFalse);
  });
}
