package kr.teeq.api.call.application.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.UUID;

public record CallHistoryRecordRequest(
    @NotBlank(message = "통화 세션 ID를 입력해 주세요.")
    @Size(max = 64, message = "통화 세션 ID는 64자 이하로 입력해 주세요.")
    @Schema(description = "AI 서버가 발급한 통화 세션 ID. 같은 값을 다시 보내면 기존 기록을 그대로 돌려준다.", example = "call-session-1234")
    String callSessionId,

    @NotNull(message = "회원 ID를 입력해 주세요.")
    @Schema(description = "통화한 회원 ID")
    UUID memberId,

    @NotNull(message = "통화 시작 시각을 입력해 주세요.")
    @Schema(description = "통화 시작 시각(ISO-8601 UTC)", example = "2026-10-16T03:00:00Z")
    Instant startedAt,

    @NotNull(message = "통화 시간을 입력해 주세요.")
    @PositiveOrZero(message = "통화 시간은 0초 이상이어야 합니다.")
    @Schema(description = "통화 시간(초). 1회 한도를 넘으면 1회 한도로 잘라 저장한다.", example = "300")
    Integer durationSeconds
) {

}
