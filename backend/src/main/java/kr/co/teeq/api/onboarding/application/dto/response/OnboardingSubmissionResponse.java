package kr.co.teeq.api.onboarding.application.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record OnboardingSubmissionResponse(
    @Schema(description = "온보딩 제출 ID")
    UUID submissionId,

    @Schema(description = "제출한 회원 ID")
    UUID memberId,

    @Schema(description = "그 회원의 몇 번째 제출인지(1부터, 제출 시각 오름차순)", example = "2")
    int submissionOrder,

    @Schema(description = "제출 시각(ISO-8601 UTC)", example = "2026-10-17T03:00:00Z")
    Instant submittedAt,

    @Schema(description = "활성 여부. 삭제되지 않은 답변이 하나라도 있으면 true", example = "true")
    boolean active,

    @Schema(description = "그 제출로 만들어진 캐릭터 결과")
    SubmissionCharacterResponse character,

    @Schema(description = "그 제출의 답변(질문 선언 순서, 삭제된 답변 포함)")
    List<OnboardingAnswerGroupResponse> answers
) {

}
