import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/features/feedback/presentation/feedback_flow_state.dart';

/// 피드백 흐름에서 선행 단계를 마쳐야 들어갈 수 있는 화면.
enum FeedbackFlowStep { completion, detailedFeedback, detailedCompletion }

/// 흐름 상태가 다른 통화이거나 필요한 선행 단계를 마치지 않았으면 홈 경로를, 아니면 null을 돌려준다.
/// 앱 시작 직후 복원된 딥링크처럼 상태가 비어 있는 진입은 모두 홈으로 보낸다.
String? feedbackFlowRedirect(
  FeedbackFlowState state,
  String callSessionId,
  FeedbackFlowStep step,
) {
  final isAllowed =
      state.callSessionId == callSessionId &&
      switch (step) {
        FeedbackFlowStep.completion => state.requiredSubmitted,
        FeedbackFlowStep.detailedFeedback =>
          state.requiredSubmitted && state.detailedFeedbackInvited,
        FeedbackFlowStep.detailedCompletion => state.detailedSubmitted,
      };
  return isAllowed ? null : AppRoutes.home;
}
