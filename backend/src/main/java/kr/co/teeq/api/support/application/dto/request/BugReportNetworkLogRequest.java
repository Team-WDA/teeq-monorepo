package kr.co.teeq.api.support.application.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.Map;

public record BugReportNetworkLogRequest(
    @NotNull(message = "네트워크 기록 시작 시각을 입력해 주세요.")
    @Schema(description = "요청 시작 시각(ISO-8601 UTC)", example = "2026-10-22T00:00:00Z")
    Instant startedAt,

    @NotBlank(message = "HTTP 메서드를 입력해 주세요.")
    @Size(max = 10, message = "HTTP 메서드는 10자 이하여야 합니다.")
    @Schema(description = "HTTP 메서드", example = "GET")
    String method,

    @NotBlank(message = "요청 주소를 입력해 주세요.")
    @Size(max = 2048, message = "요청 주소는 2048자 이하여야 합니다.")
    @Schema(description = "요청 주소")
    String url,

    @Size(max = 100, message = "요청 헤더는 100개 이하여야 합니다.")
    @Schema(description = "요청 헤더")
    Map<String, String> requestHeaders,

    @Size(max = 102400, message = "요청 본문은 102400자 이하여야 합니다.")
    @Schema(description = "요청 본문(없으면 null)")
    String requestBody,

    @Schema(description = "요청 본문이 잘렸는지 여부")
    Boolean requestBodyTruncated,

    @Schema(description = "응답 상태 코드(응답이 없으면 null)")
    Integer statusCode,

    @Size(max = 100, message = "응답 헤더는 100개 이하여야 합니다.")
    @Schema(description = "응답 헤더")
    Map<String, String> responseHeaders,

    @Size(max = 102400, message = "응답 본문은 102400자 이하여야 합니다.")
    @Schema(description = "응답 본문(없으면 null)")
    String responseBody,

    @Schema(description = "응답 본문이 잘렸는지 여부")
    Boolean responseBodyTruncated,

    @Schema(description = "소요 시간(밀리초, 없으면 null)")
    Integer durationMilliseconds,

    @Size(max = 102400, message = "에러 설명은 102400자 이하여야 합니다.")
    @Schema(description = "에러 설명(없으면 null)")
    String errorDescription
) {

    // Jackson 3은 primitive 필드가 빠지면 요청을 거부하므로 wrapper로 받고 없으면 false로 본다
    public BugReportNetworkLogRequest {
        requestBodyTruncated = Boolean.TRUE.equals(requestBodyTruncated);
        responseBodyTruncated = Boolean.TRUE.equals(responseBodyTruncated);
    }

}
