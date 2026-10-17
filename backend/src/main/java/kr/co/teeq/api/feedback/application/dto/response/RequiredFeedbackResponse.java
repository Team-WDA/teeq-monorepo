package kr.co.teeq.api.feedback.application.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;

public record RequiredFeedbackResponse(
    @Schema(description = "상세 피드백을 이어서 받아야 하는 통화인지 여부", example = "true")
    boolean detailedFeedbackInvited
) {

}
