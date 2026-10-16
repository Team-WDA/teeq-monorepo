package kr.teeq.api.feedback.application.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import java.util.List;
import kr.teeq.api.feedback.core.constant.AwkwardMoment;
import kr.teeq.api.feedback.core.constant.PreviousCallRecall;
import kr.teeq.api.feedback.core.constant.RevisitIntention;

public record RequiredFeedbackRequest(
    @NotNull(message = "통화 만족도를 입력해 주세요.")
    @Min(value = 1, message = "통화 만족도는 1~5 사이여야 합니다.")
    @Max(value = 5, message = "통화 만족도는 1~5 사이여야 합니다.")
    @Schema(description = "통화 만족도(1~5)", example = "4")
    Integer rating,

    @NotNull(message = "재통화 의향을 입력해 주세요.")
    @Schema(description = "재통화 의향", example = "YES")
    RevisitIntention revisitIntention,

    @Schema(description = "지난 통화 기억 여부. 두 번째 통화부터 필수이고 첫 통화에서는 보내면 안 된다.", example = "REMEMBERED",
        nullable = true)
    PreviousCallRecall previousCallRecall,

    @NotEmpty(message = "어색했던 순간을 1개 이상 선택해 주세요.")
    @Schema(description = "어색했던 순간 목록. 중복 불가이며 NONE은 단독으로만 선택할 수 있다.", example = "[\"CUT\", \"SLOW\"]")
    List<@NotNull(message = "어색했던 순간 선택지가 비어 있습니다.") AwkwardMoment> awkwardMoments
) {

}
