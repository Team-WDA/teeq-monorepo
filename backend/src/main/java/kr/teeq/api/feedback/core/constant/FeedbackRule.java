package kr.teeq.api.feedback.core.constant;

/**
 * 통화 순번에 따라 달라지는 피드백 규칙.
 */
public final class FeedbackRule {

    // 지난 통화 기억 문항은 두 번째 통화부터 묻는다
    private static final int PREVIOUS_CALL_RECALL_MINIMUM_CALL_INDEX = 2;
    // 상세 피드백은 세 번째 통화마다 초대한다
    private static final int DETAILED_FEEDBACK_INVITATION_INTERVAL = 3;

    private FeedbackRule() {
    }

    public static boolean isPreviousCallRecallRequired(int callIndex) {
        return callIndex >= PREVIOUS_CALL_RECALL_MINIMUM_CALL_INDEX;
    }

    public static boolean isDetailedFeedbackInvited(int callIndex) {
        return callIndex % DETAILED_FEEDBACK_INVITATION_INTERVAL == 0;
    }

}
