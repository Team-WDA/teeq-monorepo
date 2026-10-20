import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:teeq/features/feedback/domain/detailed_feedback_answers.dart';
import 'package:teeq/features/feedback/domain/feedback_status.dart';
import 'package:teeq/features/feedback/domain/required_feedback_answers.dart';

part 'feedback_flow_state.freezed.dart';

/// 통화 후 피드백 흐름(마무리 → 필수 → 완료 → 상세 → 상세 완료)이 화면 사이에 공유하는 상태.
@freezed
abstract class FeedbackFlowState with _$FeedbackFlowState {
  const factory FeedbackFlowState({
    String? callSessionId,
    FeedbackStatus? status,
    @Default(RequiredFeedbackAnswers.empty())
    RequiredFeedbackAnswers requiredAnswers,
    @Default(DetailedFeedbackAnswers.empty())
    DetailedFeedbackAnswers detailedAnswers,
    @Default(false) bool requiredSubmitted,
    @Default(false) bool detailedFeedbackInvited,
    @Default(false) bool detailedSubmitted,
    @Default(false) bool isRequestInProgress,
  }) = _FeedbackFlowState;

  static const FeedbackFlowState initial = FeedbackFlowState();
}
