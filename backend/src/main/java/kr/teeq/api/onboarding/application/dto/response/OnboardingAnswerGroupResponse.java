package kr.teeq.api.onboarding.application.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;
import kr.teeq.api.onboarding.core.constant.OnboardingOption;
import kr.teeq.api.onboarding.core.constant.OnboardingQuestion;

public record OnboardingAnswerGroupResponse(
    @Schema(description = "온보딩 질문 코드", example = "AVOID_BEHAVIOR")
    OnboardingQuestion questionCode,

    @Schema(description = "선택한 선택지 코드 목록(선택지 선언 순서)", example = "[\"AVOID_BEHAVIOR_RAPID_QUESTIONS\"]")
    List<OnboardingOption> optionCodes
) {

}
