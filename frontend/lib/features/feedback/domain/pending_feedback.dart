import 'package:freezed_annotation/freezed_annotation.dart';

part 'pending_feedback.freezed.dart';

/// 필수 피드백을 아직 제출하지 않은 통화. [callIndex]는 회원의 통화 순번(1부터)이다.
@freezed
abstract class PendingFeedback with _$PendingFeedback {
  const factory PendingFeedback({
    required String callSessionId,
    required int callIndex,
  }) = _PendingFeedback;
}
