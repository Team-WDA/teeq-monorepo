import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/features/feedback/domain/pending_feedback.dart';
import 'package:teeq/features/home/domain/pending_feedback_auto_open_policy.dart';

const _pendingFeedback = PendingFeedback(
  callSessionId: 'call-session-1',
  callIndex: 1,
);

void main() {
  group('shouldAutoOpenPendingFeedback', () {
    test('대기_피드백이_없으면_열지_않는다', () {
      expect(
        shouldAutoOpenPendingFeedback(
          pendingFeedback: null,
          lastClosedFeedbackCallSessionId: null,
        ),
        isFalse,
      );
    });

    test('방금_닫은_피드백과_같은_id면_열지_않는다', () {
      expect(
        shouldAutoOpenPendingFeedback(
          pendingFeedback: _pendingFeedback,
          lastClosedFeedbackCallSessionId: 'call-session-1',
        ),
        isFalse,
      );
    });

    test('방금_닫은_피드백이_없으면_연다', () {
      expect(
        shouldAutoOpenPendingFeedback(
          pendingFeedback: _pendingFeedback,
          lastClosedFeedbackCallSessionId: null,
        ),
        isTrue,
      );
    });

    test('방금_닫은_피드백과_다른_id면_연다', () {
      expect(
        shouldAutoOpenPendingFeedback(
          pendingFeedback: _pendingFeedback,
          lastClosedFeedbackCallSessionId: 'call-session-0',
        ),
        isTrue,
      );
    });
  });
}
