package kr.teeq.api.onboarding.application.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;

public record OnboardingAnswersResponse(
    @Schema(description = "질문별 답변 목록(질문 순서). 저장된 답변이 없으면 빈 배열")
    List<OnboardingAnswerGroupResponse> answers
) {

}
