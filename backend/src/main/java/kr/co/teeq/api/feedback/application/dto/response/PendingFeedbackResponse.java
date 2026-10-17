package kr.co.teeq.api.feedback.application.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;

public record PendingFeedbackResponse(
    @Schema(description = "필수 피드백을 제출해야 하는 통화 세션 ID", example = "call-session-1")
    String callSessionId,

    @Schema(description = "회원의 통화 순번(1부터)", example = "3")
    int callIndex
) {

}
