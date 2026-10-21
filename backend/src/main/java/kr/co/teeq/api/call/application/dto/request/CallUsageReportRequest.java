package kr.co.teeq.api.call.application.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import java.time.Instant;
import kr.co.teeq.api.call.core.constant.EndReason;

public record CallUsageReportRequest(
    @NotNull(message = "통화 사용 시간을 입력해 주세요.")
    @PositiveOrZero(message = "통화 사용 시간은 0초 이상이어야 합니다.")
    @Schema(description = "통화 사용 시간(초). 1회 한도를 넘으면 1회 한도로 잘라 저장한다.", example = "300")
    Integer usedSeconds,

    @NotNull(message = "통화 종료 시각을 입력해 주세요.")
    @Schema(description = "통화 종료 시각(ISO-8601 UTC)", example = "2026-10-16T03:05:00Z")
    Instant endedAt,

    @NotNull(message = "통화 종료 이유를 입력해 주세요.")
    @Schema(description = "통화 종료 이유. USER_HANGUP, USER_DISCONNECTED, LIMIT_REACHED, AGENT_ERROR, DISPATCH_FAILED 중 하나",
        example = "USER_HANGUP")
    EndReason endReason
) {

}
