package kr.co.teeq.api.call.application.dto.response;

import java.util.UUID;

/**
 * 회원의 가장 최근 피드백 가능 통화(종료·만료). callIndex는 {@link FeedbackTargetCall}과 같은 방식으로 센다.
 */
public record LatestFeedbackableCall(UUID callHistoryId, String callSessionId, int callIndex) {

}
