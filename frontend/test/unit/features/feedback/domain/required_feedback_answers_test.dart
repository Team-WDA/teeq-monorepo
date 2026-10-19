import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/features/feedback/domain/awkward_moment.dart';
import 'package:teeq/features/feedback/domain/previous_call_recall.dart';
import 'package:teeq/features/feedback/domain/required_feedback_answers.dart';
import 'package:teeq/features/feedback/domain/revisit_intention.dart';

RequiredFeedbackAnswers _completeWithoutRecall() =>
    const RequiredFeedbackAnswers.empty()
        .withRating(4)
        .withRevisitIntention(RevisitIntention.yes)
        .toggleAwkwardMoment(AwkwardMoment.slow)
        .toggleAwkwardMoment(AwkwardMoment.cut);

void main() {
  test('withRating_keepsValueWhenSameStarTappedAgain', () {
    final answers = const RequiredFeedbackAnswers.empty()
        .withRating(3)
        .withRating(3);

    expect(answers.rating, 3);
  });

  test('withRating_rejectsOutOfRange', () {
    const answers = RequiredFeedbackAnswers.empty();

    expect(() => answers.withRating(0), throwsArgumentError);
    expect(() => answers.withRating(6), throwsArgumentError);
  });

  test('toggleAwkwardMoment_noneClearsOthers', () {
    final answers = const RequiredFeedbackAnswers.empty()
        .toggleAwkwardMoment(AwkwardMoment.cut)
        .toggleAwkwardMoment(AwkwardMoment.slow)
        .toggleAwkwardMoment(AwkwardMoment.none);

    expect(answers.awkwardMoments, {AwkwardMoment.none});
  });

  test('toggleAwkwardMoment_otherClearsNone', () {
    final answers = const RequiredFeedbackAnswers.empty()
        .toggleAwkwardMoment(AwkwardMoment.none)
        .toggleAwkwardMoment(AwkwardMoment.repeat);

    expect(answers.awkwardMoments, {AwkwardMoment.repeat});
  });

  test('toggleAwkwardMoment_secondTapRemoves', () {
    final answers = const RequiredFeedbackAnswers.empty()
        .toggleAwkwardMoment(AwkwardMoment.cut)
        .toggleAwkwardMoment(AwkwardMoment.cut);

    expect(answers.awkwardMoments, isEmpty);
  });

  test('awkwardMoments_isUnmodifiable', () {
    final answers = const RequiredFeedbackAnswers.empty().toggleAwkwardMoment(
      AwkwardMoment.cut,
    );

    expect(
      () => answers.awkwardMoments.add(AwkwardMoment.slow),
      throwsA(anything),
    );
  });

  test('equality_comparesContent', () {
    final first = _completeWithoutRecall();
    final second = const RequiredFeedbackAnswers.empty()
        .withRating(4)
        .withRevisitIntention(RevisitIntention.yes)
        .toggleAwkwardMoment(AwkwardMoment.cut)
        .toggleAwkwardMoment(AwkwardMoment.slow);

    expect(first, second);
    expect(first.hashCode, second.hashCode);
    expect(first.withRating(5), isNot(first));
  });

  test('isComplete_firstCallNeedsNoRecall', () {
    expect(
      _completeWithoutRecall().isComplete(previousCallRecallRequired: false),
      isTrue,
    );
  });

  test('isComplete_laterCallNeedsRecall', () {
    final withoutRecall = _completeWithoutRecall();
    final withRecall = withoutRecall.withPreviousCallRecall(
      PreviousCallRecall.unsure,
    );

    expect(withoutRecall.isComplete(previousCallRecallRequired: true), isFalse);
    expect(withRecall.isComplete(previousCallRecallRequired: true), isTrue);
  });

  test('isComplete_requiresRatingIntentionAndMoment', () {
    const empty = RequiredFeedbackAnswers.empty();

    expect(empty.isComplete(previousCallRecallRequired: false), isFalse);
    expect(
      empty
          .withRating(3)
          .withRevisitIntention(RevisitIntention.no)
          .isComplete(previousCallRecallRequired: false),
      isFalse,
    );
  });

  test('toSubmission_dropsRecallOnFirstCall', () {
    final submission = _completeWithoutRecall()
        .withPreviousCallRecall(PreviousCallRecall.remembered)
        .toSubmission(previousCallRecallRequired: false);

    expect(submission!.previousCallRecall, isNull);
    expect(submission.rating, 4);
    expect(submission.revisitIntention, RevisitIntention.yes);
    expect(submission.awkwardMoments, [AwkwardMoment.cut, AwkwardMoment.slow]);
  });

  test('toSubmission_keepsRecallOnLaterCall', () {
    final submission = _completeWithoutRecall()
        .withPreviousCallRecall(PreviousCallRecall.no)
        .toSubmission(previousCallRecallRequired: true);

    expect(submission!.previousCallRecall, PreviousCallRecall.no);
  });

  test('toSubmission_nullWhenIncomplete', () {
    expect(
      const RequiredFeedbackAnswers.empty().toSubmission(
        previousCallRecallRequired: false,
      ),
      isNull,
    );
    expect(
      _completeWithoutRecall().toSubmission(previousCallRecallRequired: true),
      isNull,
    );
  });
}
