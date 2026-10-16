package kr.teeq.api.aicharacter.application.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import java.util.List;
import kr.teeq.api.aicharacter.core.constant.AiCharacterValidation;
import kr.teeq.api.onboarding.application.dto.request.OnboardingAnswerGroupRequest;

public record SubmitAiCharacterRequest(
    @NotBlank(message = "캐릭터 이름을 입력해 주세요.")
    @Pattern(regexp = AiCharacterValidation.NAME_REGEX, message = AiCharacterValidation.NAME_MESSAGE)
    @Schema(description = "캐릭터 이름. 한글, 영문, 숫자만 사용해 2~10자. 다른 회원과 같아도 된다", example = "티큐")
    String name,

    @NotNull(message = "온보딩 답변을 보내 주세요.")
    @Schema(description = "온보딩 답변. 질문 7개를 모두 답해야 한다")
    List<@NotNull @Valid OnboardingAnswerGroupRequest> answers
) {

}
