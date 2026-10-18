package kr.co.teeq.api.aicharacter.application.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import java.util.List;
import kr.co.teeq.api.onboarding.application.dto.request.OnboardingAnswerGroupRequest;

public record GenerateAiCharacterRequest(
    @NotNull(message = "온보딩 답변을 보내 주세요.")
    @Schema(description = "온보딩 답변. 질문 7개를 모두 답해야 한다")
    List<@NotNull @Valid OnboardingAnswerGroupRequest> onboardingAnswers
) {

}
