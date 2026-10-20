import 'package:teeq/features/feedback/domain/awkward_moment.dart';
import 'package:teeq/features/feedback/domain/previous_call_recall.dart';
import 'package:teeq/features/feedback/domain/required_feedback_submission.dart';
import 'package:teeq/features/feedback/domain/revisit_intention.dart';

/// 필수 피드백에서 사용자가 고른 응답. 불변이며 값으로 비교한다.
final class RequiredFeedbackAnswers {
  const RequiredFeedbackAnswers._(
    this._awkwardMoments, {
    required this.rating,
    required this.revisitIntention,
    required this.previousCallRecall,
  });

  const RequiredFeedbackAnswers.empty()
    : rating = null,
      revisitIntention = null,
      previousCallRecall = null,
      _awkwardMoments = const {};

  static const int minimumRating = 1;
  static const int maximumRating = 5;

  final int? rating;
  final RevisitIntention? revisitIntention;
  final PreviousCallRecall? previousCallRecall;
  final Set<AwkwardMoment> _awkwardMoments;

  Set<AwkwardMoment> get awkwardMoments => Set.unmodifiable(_awkwardMoments);

  /// 같은 값을 다시 줘도 값이 유지된다. 1~5 밖이면 [ArgumentError]를 던진다.
  RequiredFeedbackAnswers withRating(int rating) {
    if (rating < minimumRating || rating > maximumRating) {
      throw ArgumentError.value(
        rating,
        'rating',
        '$minimumRating~$maximumRating 사이여야 합니다.',
      );
    }
    return _copyWith(rating: rating);
  }

  RequiredFeedbackAnswers withRevisitIntention(RevisitIntention intention) =>
      _copyWith(revisitIntention: intention);

  RequiredFeedbackAnswers withPreviousCallRecall(PreviousCallRecall recall) =>
      _copyWith(previousCallRecall: recall);

  /// [AwkwardMoment.none]을 고르면 나머지가 해제되고, 다른 것을 고르면 `none`이 해제된다.
  /// 이미 고른 것을 다시 고르면 해제된다.
  RequiredFeedbackAnswers toggleAwkwardMoment(AwkwardMoment moment) {
    final Set<AwkwardMoment> next;
    if (_awkwardMoments.contains(moment)) {
      next = {..._awkwardMoments}..remove(moment);
    } else if (moment == AwkwardMoment.none) {
      next = {AwkwardMoment.none};
    } else {
      next = {..._awkwardMoments}
        ..remove(AwkwardMoment.none)
        ..add(moment);
    }
    return _copyWith(awkwardMoments: next);
  }

  /// 지난 통화 기억 응답은 [previousCallRecallRequired]일 때만 필요하다.
  bool isComplete({required bool previousCallRecallRequired}) =>
      rating != null &&
      revisitIntention != null &&
      _awkwardMoments.isNotEmpty &&
      (!previousCallRecallRequired || previousCallRecall != null);

  /// 미완성이면 null. [previousCallRecallRequired]가 false이면 기억 응답은 보내지 않는다.
  RequiredFeedbackSubmission? toSubmission({
    required bool previousCallRecallRequired,
  }) {
    if (!isComplete(previousCallRecallRequired: previousCallRecallRequired)) {
      return null;
    }
    return RequiredFeedbackSubmission(
      rating: rating!,
      revisitIntention: revisitIntention!,
      previousCallRecall: previousCallRecallRequired
          ? previousCallRecall
          : null,
      awkwardMoments: [
        for (final moment in AwkwardMoment.values)
          if (_awkwardMoments.contains(moment)) moment,
      ],
    );
  }

  RequiredFeedbackAnswers _copyWith({
    int? rating,
    RevisitIntention? revisitIntention,
    PreviousCallRecall? previousCallRecall,
    Set<AwkwardMoment>? awkwardMoments,
  }) => RequiredFeedbackAnswers._(
    awkwardMoments ?? _awkwardMoments,
    rating: rating ?? this.rating,
    revisitIntention: revisitIntention ?? this.revisitIntention,
    previousCallRecall: previousCallRecall ?? this.previousCallRecall,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is RequiredFeedbackAnswers &&
        other.rating == rating &&
        other.revisitIntention == revisitIntention &&
        other.previousCallRecall == previousCallRecall &&
        other._awkwardMoments.length == _awkwardMoments.length &&
        other._awkwardMoments.containsAll(_awkwardMoments);
  }

  @override
  int get hashCode => Object.hash(
    rating,
    revisitIntention,
    previousCallRecall,
    Object.hashAllUnordered(_awkwardMoments),
  );
}
