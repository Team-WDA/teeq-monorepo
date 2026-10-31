import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/features/home/domain/feedback_flow_path.dart';

void main() {
  group('callSessionIdFromFeedbackPath', () {
    test('피드백_흐름의_네_경로에서_통화_세션_id를_꺼낸다', () {
      for (final path in [
        AppRoutes.feedbackClosingLocation('call-session-1'),
        AppRoutes.feedbackCompletionLocation('call-session-1'),
        AppRoutes.detailedFeedbackLocation('call-session-1'),
        AppRoutes.detailedFeedbackCompletionLocation('call-session-1'),
      ]) {
        expect(callSessionIdFromFeedbackPath(path), 'call-session-1');
      }
    });

    test('인코딩된_id는_원래_값으로_되돌린다', () {
      expect(
        callSessionIdFromFeedbackPath(
          AppRoutes.feedbackClosingLocation('call session/1'),
        ),
        'call session/1',
      );
    });

    test('피드백_흐름이_아닌_경로는_null이다', () {
      for (final path in [
        AppRoutes.home,
        AppRoutes.call,
        AppRoutes.myPage,
        '/calls/call-session-1',
        '/calls/call-session-1/other',
      ]) {
        expect(callSessionIdFromFeedbackPath(path), isNull, reason: path);
      }
    });
  });
}
