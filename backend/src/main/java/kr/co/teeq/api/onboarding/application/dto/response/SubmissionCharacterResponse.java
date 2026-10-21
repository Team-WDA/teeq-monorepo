package kr.co.teeq.api.onboarding.application.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;
import kr.co.teeq.api.common.core.constant.CharacterType;

public record SubmissionCharacterResponse(
    @Schema(description = "그 제출로 만들어진 캐릭터 유형", example = "CHARACTER_3")
    CharacterType characterType,

    @Schema(description = "그 제출로 AI 서버가 발급한 persona ID")
    String personaId,

    @Schema(description = "그 제출로 만들어진 캐릭터의 성향 태그 3개")
    List<String> personalityTags
) {

}
