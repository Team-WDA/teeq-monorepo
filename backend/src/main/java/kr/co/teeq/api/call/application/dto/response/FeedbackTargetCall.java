package kr.co.teeq.api.call.application.dto.response;

import java.util.UUID;

/**
 * 피드백 대상 통화. callIndex는 회원의 FAILED를 제외한 통화 중 몇 번째 통화인지(1부터)를 뜻한다.
 */
public record FeedbackTargetCall(UUID callHistoryId, int callIndex) {

}
