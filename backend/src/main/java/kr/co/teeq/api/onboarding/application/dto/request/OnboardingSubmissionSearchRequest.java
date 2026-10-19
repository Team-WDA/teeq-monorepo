package kr.co.teeq.api.onboarding.application.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.LocalDate;
import java.util.UUID;
import kr.co.teeq.api.onboarding.core.constant.OnboardingOption;

public record OnboardingSubmissionSearchRequest(
    @Schema(description = "조회할 회원 ID. 비우면 전체 회원", nullable = true)
    UUID memberId,

    @Schema(description = "제출일 시작(KST 날짜, 포함). 비우면 제한 없음", example = "2026-10-01", nullable = true)
    LocalDate from,

    @Schema(description = "제출일 끝(KST 날짜, 포함). 비우면 제한 없음", example = "2026-10-31", nullable = true)
    LocalDate to,

    @Schema(description = "이 선택지를 포함한 제출만 조회. 비우면 제한 없음", nullable = true)
    OnboardingOption optionCode,

    @Schema(description = "활성 여부. true면 활성 답변이 있는 제출만, false면 모두 삭제된 제출만. 비우면 전체", nullable = true)
    Boolean active
) {

}
