import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/features/feedback/presentation/feedback_flow_redirect.dart';
import 'package:teeq/features/feedback/presentation/feedback_flow_state.dart';

const _callSessionId = 'call-1';

const _afterRequiredSubmit = FeedbackFlowState(
  callSessionId: _callSessionId,
  requiredSubmitted: true,
);

void main() {
  group('completion', () {
    test('completion_redirectsHomeWhenRequiredNotSubmitted', () {
      const state = FeedbackFlowState(callSessionId: _callSessionId);

      expect(
        feedbackFlowRedirect(
          state,
          _callSessionId,
          FeedbackFlowStep.completion,
        ),
        AppRoutes.home,
      );
    });

    test('completion_redirectsHomeWhenStateIsEmpty', () {
      expect(
        feedbackFlowRedirect(
          FeedbackFlowState.initial,
          _callSessionId,
          FeedbackFlowStep.completion,
        ),
        AppRoutes.home,
      );
    });

    test('completion_redirectsHomeWhenOtherCall', () {
      expect(
        feedbackFlowRedirect(
          _afterRequiredSubmit,
          'call-2',
          FeedbackFlowStep.completion,
        ),
        AppRoutes.home,
      );
    });

    test('completion_allowsAfterRequiredSubmit', () {
      expect(
        feedbackFlowRedirect(
          _afterRequiredSubmit,
          _callSessionId,
          FeedbackFlowStep.completion,
        ),
        isNull,
      );
    });
  });

  group('detailedFeedback', () {
    test('detailedFeedback_redirectsHomeWhenNotInvited', () {
      expect(
        feedbackFlowRedirect(
          _afterRequiredSubmit,
          _callSessionId,
          FeedbackFlowStep.detailedFeedback,
        ),
        AppRoutes.home,
      );
    });

    test('detailedFeedback_allowsWhenInvitedAndSubmitted', () {
      final state = _afterRequiredSubmit.copyWith(
        detailedFeedbackInvited: true,
      );

      expect(
        feedbackFlowRedirect(
          state,
          _callSessionId,
          FeedbackFlowStep.detailedFeedback,
        ),
        isNull,
      );
    });
  });

  group('detailedCompletion', () {
    test('detailedCompletion_redirectsHomeUntilDetailedSubmitted', () {
      final invited = _afterRequiredSubmit.copyWith(
        detailedFeedbackInvited: true,
      );

      expect(
        feedbackFlowRedirect(
          invited,
          _callSessionId,
          FeedbackFlowStep.detailedCompletion,
        ),
        AppRoutes.home,
      );
      expect(
        feedbackFlowRedirect(
          invited.copyWith(detailedSubmitted: true),
          _callSessionId,
          FeedbackFlowStep.detailedCompletion,
        ),
        isNull,
      );
    });

    test('detailedCompletion_redirectsHomeWhenOtherCall', () {
      final state = _afterRequiredSubmit.copyWith(
        detailedFeedbackInvited: true,
        detailedSubmitted: true,
      );

      expect(
        feedbackFlowRedirect(
          state,
          'call-2',
          FeedbackFlowStep.detailedCompletion,
        ),
        AppRoutes.home,
      );
    });
  });

  group('locations', () {
    test('feedbackClosingLocation_encodesCallSessionId', () {
      expect(
        AppRoutes.feedbackClosingLocation('call session/1'),
        '/calls/call%20session%2F1/feedback',
      );
    });

    test('otherLocations_appendFlowSegments', () {
      expect(
        AppRoutes.feedbackCompletionLocation('call-1'),
        '/calls/call-1/feedback/completion',
      );
      expect(
        AppRoutes.detailedFeedbackLocation('call-1'),
        '/calls/call-1/feedback/detail',
      );
      expect(
        AppRoutes.detailedFeedbackCompletionLocation('call-1'),
        '/calls/call-1/feedback/detail/completion',
      );
    });
  });
}
