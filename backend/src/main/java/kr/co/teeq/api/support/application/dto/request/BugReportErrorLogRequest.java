package kr.co.teeq.api.support.application.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;

public record BugReportErrorLogRequest(
    @NotNull(message = "에러 로그 시각을 입력해 주세요.")
    @Schema(description = "발생 시각(ISO-8601 UTC)", example = "2026-10-22T00:00:00Z")
    Instant timestamp,

    @NotBlank(message = "에러 로그 수준을 입력해 주세요.")
    @Size(max = 20, message = "에러 로그 수준은 20자 이하여야 합니다.")
    @Schema(description = "로그 수준", example = "SEVERE")
    String level,

    @NotBlank(message = "에러 로그 이름을 입력해 주세요.")
    @Size(max = 200, message = "에러 로그 이름은 200자 이하여야 합니다.")
    @Schema(description = "로그 이름")
    String name,

    @NotNull(message = "에러 로그 메시지를 입력해 주세요.")
    @Size(max = 102400, message = "에러 로그 메시지는 102400자 이하여야 합니다.")
    @Schema(description = "로그 메시지")
    String message,

    @Size(max = 102400, message = "에러 설명은 102400자 이하여야 합니다.")
    @Schema(description = "에러 설명(없으면 null)")
    String errorDescription,

    @Size(max = 102400, message = "스택 트레이스는 102400자 이하여야 합니다.")
    @Schema(description = "스택 트레이스 문자열(없으면 null)")
    String stackTraceText
) {

}
