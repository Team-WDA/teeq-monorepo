package kr.co.teeq.api.feedback.application.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;
import kr.co.teeq.api.feedback.core.constant.StartReason;

public record DetailedFeedbackRequest(
    @NotNull(message = "대화 타이밍 점수를 입력해 주세요.")
    @Min(value = 1, message = "점수는 1~5 사이여야 합니다.")
    @Max(value = 5, message = "점수는 1~5 사이여야 합니다.")
    @Schema(description = "대화 타이밍 점수(1~5)", example = "4")
    Integer timingScore,

    @Size(max = 100, message = "사유는 100자 이내로 입력해 주세요.")
    @Schema(description = "대화 타이밍 사유(선택, 100자 이내)", nullable = true)
    String timingReason,

    @NotNull(message = "페르소나 적합도 점수를 입력해 주세요.")
    @Min(value = 1, message = "점수는 1~5 사이여야 합니다.")
    @Max(value = 5, message = "점수는 1~5 사이여야 합니다.")
    @Schema(description = "페르소나 적합도 점수(1~5)", example = "5")
    Integer personaFitScore,

    @Size(max = 100, message = "사유는 100자 이내로 입력해 주세요.")
    @Schema(description = "페르소나 적합도 사유(선택, 100자 이내)", nullable = true)
    String personaFitReason,

    @Min(value = 1, message = "점수는 1~5 사이여야 합니다.")
    @Max(value = 5, message = "점수는 1~5 사이여야 합니다.")
    @Schema(description = "기억 점수(1~5). memoryNotApplicable이 true이면 보내면 안 되고 false이면 필수", example = "3",
        nullable = true)
    Integer memoryScore,

    @Size(max = 100, message = "사유는 100자 이내로 입력해 주세요.")
    @Schema(description = "기억 사유(선택, 100자 이내). memoryNotApplicable이 true이면 보내면 안 된다.", nullable = true)
    String memoryReason,

    @NotNull(message = "기억 문항 해당 여부를 입력해 주세요.")
    @Schema(description = "기억 관련 대화가 없어 기억 문항을 건너뛰었는지 여부", example = "false")
    Boolean memoryNotApplicable,

    @NotNull(message = "공감·신뢰 점수를 입력해 주세요.")
    @Min(value = 1, message = "점수는 1~5 사이여야 합니다.")
    @Max(value = 5, message = "점수는 1~5 사이여야 합니다.")
    @Schema(description = "공감·신뢰 점수(1~5)", example = "4")
    Integer empathyTrustScore,

    @Size(max = 100, message = "사유는 100자 이내로 입력해 주세요.")
    @Schema(description = "공감·신뢰 사유(선택, 100자 이내)", nullable = true)
    String empathyTrustReason,

    @NotNull(message = "개인 정보 편안함 점수를 입력해 주세요.")
    @Min(value = 1, message = "점수는 1~5 사이여야 합니다.")
    @Max(value = 5, message = "점수는 1~5 사이여야 합니다.")
    @Schema(description = "개인적인 이야기를 해도 편안한 정도 점수(1~5)", example = "4")
    Integer personalComfortScore,

    @Size(max = 100, message = "사유는 100자 이내로 입력해 주세요.")
    @Schema(description = "개인적인 이야기 편안함 사유(선택, 100자 이내)", nullable = true)
    String personalComfortReason,

    @NotNull(message = "저장 편안함 점수를 입력해 주세요.")
    @Min(value = 1, message = "점수는 1~5 사이여야 합니다.")
    @Max(value = 5, message = "점수는 1~5 사이여야 합니다.")
    @Schema(description = "대화 내용이 저장되는 것에 대한 편안함 점수(1~5)", example = "3")
    Integer storageComfortScore,

    @Size(max = 100, message = "사유는 100자 이내로 입력해 주세요.")
    @Schema(description = "저장 편안함 사유(선택, 100자 이내)", nullable = true)
    String storageComfortReason,

    @Size(max = 1000, message = "자유 서술은 1000자 이내로 입력해 주세요.")
    @Schema(description = "자유 서술(선택, 1000자 이내)", nullable = true)
    String freeText,

    @NotEmpty(message = "통화를 시작한 이유를 1개 이상 선택해 주세요.")
    @Schema(description = "통화 시작 이유 목록. 중복 불가", example = "[\"NEED_TO_TALK\", \"OTHER\"]")
    List<@NotNull(message = "통화 시작 이유 선택지가 비어 있습니다.") StartReason> startReasons,

    @Size(max = 100, message = "기타 이유는 100자 이내로 입력해 주세요.")
    @Schema(description = "기타 시작 이유(선택, 100자 이내). startReasons에 OTHER가 있을 때만 보낼 수 있다.", nullable = true)
    String startReasonOtherText
) {

}
