package kr.co.teeq.api.call.application.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;

public record MemberTodayCallLimitResponse(
    @Schema(description = "하루 기본 통화 한도(초)", example = "1800")
    long dailyLimitSeconds,

    @Schema(description = "오늘(KST) 유효한 추가 통화 시간 합계(초). 취소된 보너스는 제외", example = "300")
    long todayBonusSeconds,

    @Schema(description = "오늘(KST) 사용한 통화 시간(초)", example = "400")
    long usedSeconds,

    @Schema(description = "오늘 남은 통화 시간(초). 한도를 넘겼으면 0", example = "1700")
    long remainingSeconds
) {

}
