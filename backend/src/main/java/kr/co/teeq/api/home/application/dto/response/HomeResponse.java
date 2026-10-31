package kr.co.teeq.api.home.application.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;
import kr.co.teeq.api.call.application.dto.response.CallLimitStatusResponse;
import kr.co.teeq.api.common.core.constant.CharacterType;
import kr.co.teeq.api.feedback.application.dto.response.PendingFeedbackResponse;
import kr.co.teeq.api.home.core.constant.CharacterMood;

public record HomeResponse(
    @Schema(description = "캐릭터 이름", example = "티크")
    String characterName,

    @Schema(description = "AI 서버가 정한 캐릭터 유형. 홈 캐릭터 이미지의 외형을 고른다", example = "CHARACTER_3")
    CharacterType characterType,

    @Schema(description = "캐릭터 표정. 오늘의 한마디와 함께 AI 서버가 정하며, 기본 문구이거나 알 수 없는 값이면 WELCOME이다",
        example = "CURIOUS")
    CharacterMood characterMood,

    @Schema(description = "캐릭터 성향 태그 3개", example = "[\"다정한\", \"차분한\", \"든든한\"]")
    List<String> personalityTags,

    @Schema(description = "오늘의 한마디. 줄바꿈(\\n)을 포함할 수 있다", example = "소연아,\n오늘 하루 어땠어?\n무슨 일 있었는지 궁금한데...")
    String greeting,

    @Schema(description = "오늘 통화 한도")
    CallLimitStatusResponse callLimit,

    @Schema(description = "필수 피드백을 제출해야 하는 통화. 없으면 null", nullable = true)
    PendingFeedbackResponse pendingFeedback
) {

}
