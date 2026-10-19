package kr.co.teeq.api.onboarding.application.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;

public record SubmissionCharacterResponse(
    @Schema(description = "그 제출로 만들어진 캐릭터 번호", example = "3")
    int characterNumber,

    @Schema(description = "그 제출로 만들어진 캐릭터의 성향 태그 3개")
    List<String> personalityTags
) {

}
