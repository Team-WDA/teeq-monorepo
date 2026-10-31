package kr.co.teeq.api.onboarding.application.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;
import kr.co.teeq.api.onboarding.core.constant.OnboardingOption;
import kr.co.teeq.api.onboarding.core.constant.OnboardingQuestion;

public record OnboardingQuestionResponse(
    @Schema(description = "온보딩 질문 코드", example = "AVOID_BEHAVIOR")
    OnboardingQuestion questionCode,

    @Schema(description = "최소 선택 개수", example = "1")
    int minSelections,

    @Schema(description = "최대 선택 개수", example = "5")
    int maxSelections,

    @Schema(description = "선택 가능한 선택지 코드 목록(선택지 선언 순서)", example = "[\"AVOID_BEHAVIOR_RAPID_QUESTIONS\"]")
    List<OnboardingOption> optionCodes
) {

}
