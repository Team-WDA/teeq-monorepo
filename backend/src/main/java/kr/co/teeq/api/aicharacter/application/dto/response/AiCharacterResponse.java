package kr.co.teeq.api.aicharacter.application.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;
import kr.co.teeq.api.aicharacter.core.entity.AiCharacter;

public record AiCharacterResponse(
    @Schema(description = "캐릭터 이름", example = "티큐")
    String name,

    @Schema(description = "AI 서버가 정한 캐릭터 번호", example = "3")
    int characterNumber,

    @Schema(description = "성향 태그 3개", example = "[\"다정한\", \"차분한\", \"든든한\"]")
    List<String> personalityTags
) {

    public static AiCharacterResponse from(AiCharacter aiCharacter) {
        return new AiCharacterResponse(aiCharacter.getName(), aiCharacter.getCharacterNumber(),
            aiCharacter.getPersonalityTags());
    }

}
