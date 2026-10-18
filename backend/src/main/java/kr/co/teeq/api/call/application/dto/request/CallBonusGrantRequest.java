package kr.co.teeq.api.call.application.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import kr.co.teeq.api.call.core.constant.CallBonusPolicy;

public record CallBonusGrantRequest(
    @NotNull(message = "추가 통화 시간을 입력해 주세요.")
    @Min(value = CallBonusPolicy.MIN_SECONDS, message = "추가 통화 시간은 1초 이상이어야 합니다.")
    @Max(value = CallBonusPolicy.MAX_SECONDS, message = "추가 통화 시간은 3600초 이하여야 합니다.")
    @Schema(description = "추가 통화 시간(초). 1~3600", example = "600")
    Integer seconds,

    @Schema(description = "추가 시간이 유효한 날짜(KST). 비우면 오늘이며 과거 날짜는 허용하지 않는다", example = "2026-10-18")
    LocalDate bonusDate,

    @NotBlank(message = "부여 사유를 입력해 주세요.")
    @Size(max = CallBonusPolicy.MAX_REASON_LENGTH, message = "부여 사유는 200자 이하로 입력해 주세요.")
    @Schema(description = "부여 사유(200자 이하)", example = "서비스 장애 보상")
    String reason
) {

}
