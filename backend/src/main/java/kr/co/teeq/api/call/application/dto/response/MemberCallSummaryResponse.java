package kr.co.teeq.api.call.application.dto.response;

import java.time.Instant;

/**
 * 회원의 통화 요약. lastStartedAt은 통화가 없으면 null이다.
 */
public record MemberCallSummaryResponse(
    long callCount,
    long usedSeconds,
    Instant lastStartedAt,
    long recentCallCount
) {

}
