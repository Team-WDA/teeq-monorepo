package kr.co.teeq.api.aicharacter.application.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import kr.co.teeq.api.aicharacter.core.constant.AiCharacterValidation;

public record RenameAiCharacterRequest(
    @NotBlank(message = "캐릭터 이름을 입력해 주세요.")
    @Pattern(regexp = AiCharacterValidation.NAME_REGEX, message = AiCharacterValidation.NAME_MESSAGE)
    @Schema(description = "캐릭터 이름. 한글, 영문, 숫자만 사용해 2~10자. 다른 회원과 같아도 된다", example = "티큐")
    String name
) {

}
