import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/features/onboarding/domain/onboarding_option.dart';
import 'package:teeq/features/onboarding/domain/onboarding_selections.dart';

import '../../../../support/fake_onboarding_catalog_repository.dart';

final _relationship = testOnboardingQuestion('RELATIONSHIP');
final _avoidBehavior = testOnboardingQuestion('AVOID_BEHAVIOR');
final _closeFriend = testOnboardingOption('RELATIONSHIP_CLOSE_FRIEND');
final _lifeMentor = testOnboardingOption('RELATIONSHIP_LIFE_MENTOR');
final _rapidQuestions = testOnboardingOption('AVOID_BEHAVIOR_RAPID_QUESTIONS');
final _interrupting = testOnboardingOption('AVOID_BEHAVIOR_INTERRUPTING');

OnboardingSelections _answerAll() {
  var selections = const OnboardingSelections.empty();
  for (final question in testOnboardingCatalog.questions) {
    selections = selections.toggle(question, question.options.first);
  }
  return selections;
}

void main() {
  test('toggle_singleChoice_replacesPreviousSelection', () {
    final selections = const OnboardingSelections.empty()
        .toggle(_relationship, _closeFriend)
        .toggle(_relationship, _lifeMentor);

    expect(selections.selectedFor(_relationship), {_lifeMentor});
  });

  test('toggle_singleChoice_sameOptionTwice_keepsSelection', () {
    final selections = const OnboardingSelections.empty()
        .toggle(_relationship, _closeFriend)
        .toggle(_relationship, _closeFriend);

    expect(selections.selectedFor(_relationship), {_closeFriend});
  });

  test('toggle_multipleChoice_addsAndRemoves', () {
    var selections = const OnboardingSelections.empty()
        .toggle(_avoidBehavior, _rapidQuestions)
        .toggle(_avoidBehavior, _interrupting);
    expect(selections.selectedFor(_avoidBehavior), {
      _rapidQuestions,
      _interrupting,
    });

    selections = selections.toggle(_avoidBehavior, _rapidQuestions);
    expect(selections.selectedFor(_avoidBehavior), {_interrupting});
  });

  test('toggle_multipleChoice_allFiveOptionsSelectable', () {
    var selections = const OnboardingSelections.empty();
    for (final option in _avoidBehavior.options) {
      selections = selections.toggle(_avoidBehavior, option);
    }

    expect(
      selections.selectedFor(_avoidBehavior),
      _avoidBehavior.options.toSet(),
    );
  });

  test('toggle_multipleChoice_cannotExceedMaxSelections', () {
    // 최대 선택 수를 넘기는지만 보려고 질문 밖의 여섯 번째 선택지를 만든다.
    const extraOption = OnboardingOption(
      code: 'AVOID_BEHAVIOR_EXTRA',
      label: '추가 선택지',
    );
    final question = _avoidBehavior;
    var selections = const OnboardingSelections.empty();
    for (final option in question.options) {
      selections = selections.toggle(question, option);
    }

    final afterExtra = selections.toggle(question, extraOption);

    expect(afterExtra.selectedFor(question), hasLength(5));
    expect(afterExtra.selectedFor(question).contains(extraOption), isFalse);
  });

  test('isAnswered_multipleChoice_zeroSelected_false', () {
    final selections = const OnboardingSelections.empty()
        .toggle(_avoidBehavior, _rapidQuestions)
        .toggle(_avoidBehavior, _rapidQuestions);

    expect(selections.isAnswered(_avoidBehavior), isFalse);
  });

  test('isComplete_onlyWhenAllQuestionsMeetMinSelections', () {
    expect(
      const OnboardingSelections.empty().isComplete(testOnboardingCatalog),
      isFalse,
    );
    expect(_answerAll().isComplete(testOnboardingCatalog), isTrue);

    final withoutLast = _answerAll().toggle(_avoidBehavior, _rapidQuestions);
    expect(withoutLast.isComplete(testOnboardingCatalog), isFalse);
  });

  test('toggle_returnsNewInstance_doesNotMutate', () {
    const original = OnboardingSelections.empty();
    final toggled = original.toggle(_relationship, _closeFriend);

    expect(identical(original, toggled), isFalse);
    expect(original.selectedFor(_relationship), isEmpty);
  });

  test('equality_isValueBased', () {
    final first = const OnboardingSelections.empty().toggle(
      _relationship,
      _closeFriend,
    );
    final second = const OnboardingSelections.empty().toggle(
      _relationship,
      _closeFriend,
    );

    expect(first, second);
    expect(first.hashCode, second.hashCode);
    expect(first == const OnboardingSelections.empty(), isFalse);
  });

  test('equality_deselectedQuestionEqualsUntouched', () {
    final deselected = const OnboardingSelections.empty()
        .toggle(_avoidBehavior, _rapidQuestions)
        .toggle(_avoidBehavior, _rapidQuestions);

    expect(deselected, const OnboardingSelections.empty());
    expect(deselected.hashCode, const OnboardingSelections.empty().hashCode);
  });
}
