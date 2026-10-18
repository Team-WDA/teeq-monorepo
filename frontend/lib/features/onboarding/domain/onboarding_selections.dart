import 'package:teeq/features/onboarding/domain/onboarding_option.dart';
import 'package:teeq/features/onboarding/domain/onboarding_question.dart';

/// 질문별로 고른 선택지. 불변이며 값으로 비교한다.
final class OnboardingSelections {
  const OnboardingSelections._(this._selected);

  const OnboardingSelections.empty() : _selected = const {};

  final Map<OnboardingQuestion, Set<OnboardingOption>> _selected;

  Set<OnboardingOption> selectedFor(OnboardingQuestion question) =>
      Set.unmodifiable(_selected[question] ?? const <OnboardingOption>{});

  Map<OnboardingQuestion, Set<OnboardingOption>> get answers =>
      Map.unmodifiable({
        for (final entry in _selected.entries)
          entry.key: Set<OnboardingOption>.unmodifiable(entry.value),
      });

  bool isAnswered(OnboardingQuestion question) =>
      selectedFor(question).length >= question.minSelections;

  bool get isComplete => OnboardingQuestion.values.every(isAnswered);

  /// 단일 선택은 같은 질문의 기존 선택을 대체하고, 복수 선택은 있으면 해제하고 없으면 추가한다.
  OnboardingSelections toggle(OnboardingOption option) {
    final question = option.question;
    final current = selectedFor(question);
    final Set<OnboardingOption> next;
    if (!question.isMultipleChoice) {
      if (current.contains(option)) {
        return this;
      }
      next = {option};
    } else if (current.contains(option)) {
      next = {...current}..remove(option);
    } else if (current.length >= question.maxSelections) {
      return this;
    } else {
      next = {...current, option};
    }
    return OnboardingSelections._({..._selected, question: next});
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! OnboardingSelections) {
      return false;
    }
    return OnboardingQuestion.values.every((question) {
      final mine = selectedFor(question);
      final theirs = other.selectedFor(question);
      return mine.length == theirs.length && mine.containsAll(theirs);
    });
  }

  @override
  int get hashCode => Object.hashAll(
    OnboardingQuestion.values.map(
      (question) => Object.hashAllUnordered(selectedFor(question)),
    ),
  );
}
