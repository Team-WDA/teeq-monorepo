package kr.co.teeq.api.call.application.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;
import kr.co.teeq.api.call.core.entity.CallBonus;

public record CallBonusResponse(
    @Schema(description = "추가 통화 시간 ID")
    UUID id,

    @Schema(description = "부여 대상 회원 ID")
    UUID memberId,

    @Schema(description = "추가 시간이 유효한 날짜(KST)", example = "2026-10-18")
    LocalDate bonusDate,

    @Schema(description = "추가 통화 시간(초)", example = "600")
    int seconds,

    @Schema(description = "부여 사유", example = "서비스 장애 보상")
    String reason,

    @Schema(description = "부여한 관리자 회원 ID")
    UUID grantedByMemberId,

    @Schema(description = "취소 여부", example = "false")
    boolean canceled,

    @Schema(description = "취소 시각(ISO-8601 UTC). 취소되지 않았으면 null", nullable = true)
    Instant canceledAt,

    @Schema(description = "취소한 관리자 회원 ID. 취소되지 않았으면 null", nullable = true)
    UUID canceledByMemberId,

    @Schema(description = "부여 시각(ISO-8601 UTC)", example = "2026-10-17T03:00:00Z")
    Instant createdAt
) {

    public static CallBonusResponse from(CallBonus callBonus) {
        return new CallBonusResponse(callBonus.getId(), callBonus.getMemberId(), callBonus.getBonusDate(),
            callBonus.getSeconds(), callBonus.getReason(), callBonus.getGrantedByMemberId(),
            callBonus.isDeleted(), callBonus.getDeletedAt(), callBonus.getCanceledByMemberId(),
            callBonus.getCreatedAt());
    }

}
