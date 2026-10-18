package kr.co.teeq.api.feedback.application.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;

public record FeedbackStatusResponse(
    @Schema(description = "회원의 통화 순번(1부터). 실패한 통화는 세지 않는다.", example = "3")
    int callIndex,

    @Schema(description = "지난 통화 기억 문항을 보내야 하는지 여부(두 번째 통화부터 true)", example = "true")
    boolean previousCallRecallRequired,

    @Schema(description = "이 통화의 필수 피드백 제출 여부", example = "false")
    boolean requiredFeedbackSubmitted
) {

}
