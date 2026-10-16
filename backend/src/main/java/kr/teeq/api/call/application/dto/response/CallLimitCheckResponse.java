package kr.teeq.api.call.application.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;

public record CallLimitCheckResponse(
    @Schema(description = "이번 통화에서 허용되는 최대 시간(초). 1회 한도와 오늘 남은 시간 중 작은 값", example = "1200")
    long allowedSeconds
) {

}
