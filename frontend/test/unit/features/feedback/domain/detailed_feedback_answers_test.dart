import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/features/feedback/domain/detailed_feedback_answers.dart';
import 'package:teeq/features/feedback/domain/detailed_feedback_question.dart';
import 'package:teeq/features/feedback/domain/feedback_input_limits.dart';
import 'package:teeq/features/feedback/domain/start_reason.dart';

const _otherQuestions = [
  DetailedFeedbackQuestion.timing,
  DetailedFeedbackQuestion.personaFit,
  DetailedFeedbackQuestion.empathyTrust,
  DetailedFeedbackQuestion.personalComfort,
  DetailedFeedbackQuestion.storageComfort,
];

DetailedFeedbackAnswers _withScoresExceptMemory() {
  var answers = const DetailedFeedbackAnswers.empty();
  for (final question in _otherQuestions) {
    answers = answers.withScore(question, 4);
  }
  return answers;
}

void main() {
  test('withScore_rejectsOutOfRange', () {
    const answers = DetailedFeedbackAnswers.empty();

    expect(
      () => answers.withScore(DetailedFeedbackQuestion.timing, 0),
      throwsArgumentError,
    );
    expect(
      () => answers.withScore(DetailedFeedbackQuestion.timing, 6),
      throwsArgumentError,
    );
  });

  test('withMemoryNotApplicable_clearsMemoryScoreAndReason', () {
    final answers = const DetailedFeedbackAnswers.empty()
        .withScore(DetailedFeedbackQuestion.memory, 3)
        .withReason(DetailedFeedbackQuestion.memory, '이유')
        .withMemoryNotApplicable(true);

    expect(answers.memoryNotApplicable, isTrue);
    expect(
      answers.scores.containsKey(DetailedFeedbackQuestion.memory),
      isFalse,
    );
    expect(
      answers.reasons.containsKey(DetailedFeedbackQuestion.memory),
      isFalse,
    );
  });

  test('withScore_ignoredForMemoryWhenNotApplicable', () {
    final answers = const DetailedFeedbackAnswers.empty()
        .withMemoryNotApplicable(true)
        .withScore(DetailedFeedbackQuestion.memory, 5)
        .withReason(DetailedFeedbackQuestion.memory, '이유');

    expect(answers.scores, isEmpty);
    expect(answers.reasons, isEmpty);
  });

  test('withMemoryNotApplicable_falseAgainRequiresScore', () {
    final answers = _withScoresExceptMemory()
        .toggleStartReason(StartReason.needToTalk)
        .withMemoryNotApplicable(true)
        .withMemoryNotApplicable(false);

    expect(answers.memoryNotApplicable, isFalse);
    expect(
      answers.scores.containsKey(DetailedFeedbackQuestion.memory),
      isFalse,
    );
    expect(
      answers.reasons.containsKey(DetailedFeedbackQuestion.memory),
      isFalse,
    );
    expect(answers.isMemoryScoreRequired, isTrue);
    expect(answers.isComplete, isFalse);
  });

  test('toggleStartReason_deselectingOtherClearsOtherText', () {
    final answers = const DetailedFeedbackAnswers.empty()
        .toggleStartReason(StartReason.other)
        .withStartReasonOtherText('그냥')
        .toggleStartReason(StartReason.other);

    expect(answers.startReasons, isEmpty);
    expect(answers.startReasonOtherText, '');
    expect(answers.isStartReasonOtherTextEnabled, isFalse);
  });

  test('withStartReasonOtherText_ignoredUnlessOtherSelected', () {
    final answers = const DetailedFeedbackAnswers.empty()
        .toggleStartReason(StartReason.needToTalk)
        .withStartReasonOtherText('그냥');

    expect(answers.startReasonOtherText, '');
  });

  test('withStartReasonOtherText_truncatesAtLimit', () {
    final answers = const DetailedFeedbackAnswers.empty()
        .toggleStartReason(StartReason.other)
        .withStartReasonOtherText(
          'a' * (FeedbackInputLimits.startReasonOtherTextMaxLength + 1),
        );

    expect(
      answers.startReasonOtherText.length,
      FeedbackInputLimits.startReasonOtherTextMaxLength,
    );
  });

  test('withReason_truncatesAtLimit', () {
    final answers = const DetailedFeedbackAnswers.empty().withReason(
      DetailedFeedbackQuestion.timing,
      'a' * (FeedbackInputLimits.reasonMaxLength + 1),
    );

    expect(
      answers.reasons[DetailedFeedbackQuestion.timing]!.length,
      FeedbackInputLimits.reasonMaxLength,
    );
  });

  test('withReason_doesNotSplitSurrogatePairAtLimit', () {
    final answers = const DetailedFeedbackAnswers.empty().withReason(
      DetailedFeedbackQuestion.timing,
      '${'가' * (FeedbackInputLimits.reasonMaxLength - 1)}😀',
    );

    expect(
      answers.reasons[DetailedFeedbackQuestion.timing],
      '가' * (FeedbackInputLimits.reasonMaxLength - 1),
    );
  });

  test('withFreeText_truncatesAtLimit', () {
    final answers = const DetailedFeedbackAnswers.empty().withFreeText(
      'a' * (FeedbackInputLimits.freeTextMaxLength + 1),
    );

    expect(answers.freeText.length, FeedbackInputLimits.freeTextMaxLength);
  });

  test('exposedCollections_areUnmodifiable', () {
    final answers = _withScoresExceptMemory().toggleStartReason(
      StartReason.needToTalk,
    );

    expect(
      () => answers.scores[DetailedFeedbackQuestion.timing] = 1,
      throwsA(anything),
    );
    expect(
      () => answers.reasons[DetailedFeedbackQuestion.timing] = 'x',
      throwsA(anything),
    );
    expect(
      () => answers.startReasons.add(StartReason.other),
      throwsA(anything),
    );
  });

  test('equality_comparesContent', () {
    final first = _withScoresExceptMemory().toggleStartReason(
      StartReason.needToTalk,
    );
    final second = _withScoresExceptMemory().toggleStartReason(
      StartReason.needToTalk,
    );

    expect(first, second);
    expect(first.hashCode, second.hashCode);
    expect(first.withFreeText('a'), isNot(first));
  });

  test('isComplete_requiresStartReason', () {
    final answers = _withScoresExceptMemory().withMemoryNotApplicable(true);

    expect(answers.isComplete, isFalse);
    expect(
      answers.toggleStartReason(StartReason.needToTalk).isComplete,
      isTrue,
    );
  });

  test('isComplete_allowsMemoryNotApplicableWithoutMemoryScore', () {
    final answers = _withScoresExceptMemory()
        .withMemoryNotApplicable(true)
        .toggleStartReason(StartReason.testingService);

    expect(answers.isMemoryScoreRequired, isFalse);
    expect(answers.isComplete, isTrue);
  });

  test('isComplete_requiresMemoryScoreWhenApplicable', () {
    final base = _withScoresExceptMemory().toggleStartReason(
      StartReason.needToTalk,
    );

    expect(base.isComplete, isFalse);
    expect(
      base.withScore(DetailedFeedbackQuestion.memory, 2).isComplete,
      isTrue,
    );
  });

  test('toSubmission_nullWhenIncomplete', () {
    expect(const DetailedFeedbackAnswers.empty().toSubmission(), isNull);
  });

  test('toSubmission_trimsAndDropsBlankText', () {
    final submission = _withScoresExceptMemory()
        .withScore(DetailedFeedbackQuestion.memory, 3)
        .withReason(DetailedFeedbackQuestion.timing, '  좋았어요  ')
        .withReason(DetailedFeedbackQuestion.personaFit, '   ')
        .withFreeText('   ')
        .toggleStartReason(StartReason.wantToConfide)
        .toggleStartReason(StartReason.needToTalk)
        .toSubmission();

    expect(submission!.reasons, {DetailedFeedbackQuestion.timing: '좋았어요'});
    expect(submission.freeText, isNull);
    expect(submission.startReasons, [
      StartReason.needToTalk,
      StartReason.wantToConfide,
    ]);
    expect(submission.scores.length, 6);
  });

  test('toSubmission_omitsMemoryFieldsWhenNotApplicable', () {
    final submission = _withScoresExceptMemory()
        .withMemoryNotApplicable(true)
        .withFreeText(' 자유 ')
        .toggleStartReason(StartReason.needToTalk)
        .toSubmission();

    expect(submission!.memoryNotApplicable, isTrue);
    expect(
      submission.scores.containsKey(DetailedFeedbackQuestion.memory),
      isFalse,
    );
    expect(
      submission.reasons.containsKey(DetailedFeedbackQuestion.memory),
      isFalse,
    );
    expect(submission.freeText, '자유');
  });

  test('toSubmission_sendsOtherTextOnlyWhenOtherSelected', () {
    final withOther = _withScoresExceptMemory()
        .withMemoryNotApplicable(true)
        .toggleStartReason(StartReason.other)
        .withStartReasonOtherText(' 그냥 ')
        .toSubmission();
    final blankOther = _withScoresExceptMemory()
        .withMemoryNotApplicable(true)
        .toggleStartReason(StartReason.other)
        .withStartReasonOtherText('  ')
        .toSubmission();
    final withoutOther = _withScoresExceptMemory()
        .withMemoryNotApplicable(true)
        .toggleStartReason(StartReason.needToTalk)
        .toSubmission();

    expect(withOther!.startReasonOtherText, '그냥');
    expect(blankOther!.startReasonOtherText, isNull);
    expect(withoutOther!.startReasonOtherText, isNull);
  });
}
