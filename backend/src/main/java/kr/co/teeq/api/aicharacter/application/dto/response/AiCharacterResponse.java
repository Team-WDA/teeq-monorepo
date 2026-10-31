package kr.co.teeq.api.aicharacter.application.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;
import kr.co.teeq.api.aicharacter.core.entity.AiCharacter;
import kr.co.teeq.api.common.core.constant.CharacterType;

public record AiCharacterResponse(
    @Schema(description = "캐릭터 이름", example = "티크")
    String name,

    @Schema(description = "AI 서버가 정한 캐릭터 유형", example = "CHARACTER_3")
    CharacterType characterType,

    @Schema(description = "성향 태그 3개", example = "[\"다정한\", \"차분한\", \"든든한\"]")
    List<String> personalityTags
) {

    public static AiCharacterResponse from(AiCharacter aiCharacter) {
        return new AiCharacterResponse(aiCharacter.getName(), aiCharacter.getCharacterType(),
            aiCharacter.getPersonalityTags());
    }

}
