import 'package:teeq/features/onboarding/domain/onboarding_catalog.dart';
import 'package:teeq/features/onboarding/domain/onboarding_option.dart';
import 'package:teeq/features/onboarding/domain/onboarding_question.dart';

/// 질문 코드별로 고른 선택지. 불변이며 값으로 비교한다.
final class OnboardingSelections {
  const OnboardingSelections._(this._selected);

  const OnboardingSelections.empty() : _selected = const {};

  /// 키는 질문 코드.
  final Map<String, Set<OnboardingOption>> _selected;

  Set<OnboardingOption> selectedFor(OnboardingQuestion question) =>
      Set.unmodifiable(_selected[question.code] ?? const <OnboardingOption>{});

  /// 질문 코드별 선택.
  Map<String, Set<OnboardingOption>> get answers => Map.unmodifiable({
    for (final entry in _selected.entries)
      entry.key: Set<OnboardingOption>.unmodifiable(entry.value),
  });

  bool isAnswered(OnboardingQuestion question) =>
      selectedFor(question).length >= question.minSelections;

  bool isComplete(OnboardingCatalog catalog) =>
      catalog.questions.every(isAnswered);

  /// 단일 선택은 같은 질문의 기존 선택을 대체하고, 복수 선택은 있으면 해제하고 없으면 추가한다.
  OnboardingSelections toggle(
    OnboardingQuestion question,
    OnboardingOption option,
  ) {
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
    return OnboardingSelections._({..._selected, question.code: next});
  }

  /// 선택이 하나 이상 있는 질문 코드만 본다(해제해서 비어 있는 질문은 고르지 않은 것과 같다).
  Map<String, Set<OnboardingOption>> get _nonEmptySelections => {
    for (final entry in _selected.entries)
      if (entry.value.isNotEmpty) entry.key: entry.value,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! OnboardingSelections) {
      return false;
    }
    final mine = _nonEmptySelections;
    final theirs = other._nonEmptySelections;
    if (mine.length != theirs.length) {
      return false;
    }
    return mine.entries.every((entry) {
      final theirOptions = theirs[entry.key];
      return theirOptions != null &&
          theirOptions.length == entry.value.length &&
          theirOptions.containsAll(entry.value);
    });
  }

  @override
  int get hashCode => Object.hashAllUnordered(
    _nonEmptySelections.entries.map(
      (entry) => Object.hash(entry.key, Object.hashAllUnordered(entry.value)),
    ),
  );
}
