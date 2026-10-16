package kr.teeq.api.onboarding.application.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import java.util.List;
import kr.teeq.api.onboarding.core.constant.OnboardingOption;
import kr.teeq.api.onboarding.core.constant.OnboardingQuestion;

public record OnboardingAnswerGroupRequest(
    @Schema(description = "온보딩 질문 코드", example = "AVOID_BEHAVIOR")
    @NotNull
    OnboardingQuestion questionCode,

    @Schema(description = "선택한 선택지 코드 목록. 복수 선택 질문만 2개 이상 가능", example = "[\"AVOID_BEHAVIOR_RAPID_QUESTIONS\"]")
    @NotNull
    List<@NotNull OnboardingOption> optionCodes
) {

}
