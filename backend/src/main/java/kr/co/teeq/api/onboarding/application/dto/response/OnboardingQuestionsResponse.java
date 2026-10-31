package kr.co.teeq.api.onboarding.application.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;

public record OnboardingQuestionsResponse(
    @Schema(description = "온보딩 질문 목록(질문 순서)")
    List<OnboardingQuestionResponse> questions
) {

}
