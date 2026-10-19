package kr.co.teeq.api.onboarding.application.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;

public record OnboardingSubmissionPageResponse(
    @Schema(description = "현재 페이지의 온보딩 제출 목록(제출 시각 내림차순)")
    List<OnboardingSubmissionResponse> items,

    @Schema(description = "현재 페이지 번호(0부터)", example = "0")
    int page,

    @Schema(description = "페이지 크기", example = "20")
    int size,

    @Schema(description = "조건에 맞는 전체 제출 수", example = "42")
    long totalElements
) {

}
