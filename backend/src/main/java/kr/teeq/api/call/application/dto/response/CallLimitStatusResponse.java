package kr.teeq.api.call.application.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;

public record CallLimitStatusResponse(
    @Schema(description = "오늘(KST) 사용한 통화 시간(초)", example = "300")
    long usedSeconds,

    @Schema(description = "오늘 남은 통화 시간(초). 일 한도를 넘겼으면 0", example = "1500")
    long remainingSeconds,

    @Schema(description = "이번 통화에서 허용되는 최대 시간(초). 1회 한도와 남은 시간 중 작은 값", example = "1200")
    long allowedSeconds,

    @Schema(description = "통화를 시작할 수 있는지 여부. 남은 시간이 최소 시작 시간 이상이면 true", example = "true")
    boolean canStart
) {

}
