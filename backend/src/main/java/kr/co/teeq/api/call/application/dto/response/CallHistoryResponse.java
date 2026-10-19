package kr.co.teeq.api.call.application.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.util.UUID;
import kr.co.teeq.api.call.core.constant.CallStatus;
import kr.co.teeq.api.call.core.entity.CallHistory;

public record CallHistoryResponse(
    @Schema(description = "AI 서버가 발급한 통화 세션 ID", example = "call-session-1234")
    String callSessionId,

    @Schema(description = "통화한 회원 ID")
    UUID memberId,

    @Schema(description = "통화 시작 시각(ISO-8601 UTC)", example = "2026-10-16T03:00:00Z")
    Instant startedAt,

    @Schema(description = "저장된 통화 시간(초)", example = "300")
    int durationSeconds,

    @Schema(description = "통화 기록 상태", example = "ENDED")
    CallStatus status
) {

    public static CallHistoryResponse from(CallHistory callHistory) {
        return new CallHistoryResponse(callHistory.getCallSessionId(), callHistory.getMember().getId(),
            callHistory.getStartedAt(), callHistory.getDurationSeconds(), callHistory.getStatus());
    }

}
