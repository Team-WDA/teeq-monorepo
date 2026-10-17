package kr.co.teeq.api.call.application.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.LocalDate;

public record CallUsageResponse(
    @Schema(description = "기간 시작 날짜(KST). 일별이면 해당 일, 월별이면 해당 월 1일", example = "2026-10-01")
    LocalDate periodStart,

    @Schema(description = "기간 내 통화 시작 기준 사용 시간(초) 합계", example = "5400")
    long usedSeconds,

    @Schema(description = "기간 내 통화 횟수. 실패·대기 중 통화는 제외", example = "12")
    long callCount
) {

}
