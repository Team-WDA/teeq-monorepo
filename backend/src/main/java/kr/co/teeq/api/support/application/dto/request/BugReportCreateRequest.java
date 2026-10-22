package kr.co.teeq.api.support.application.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;
import java.util.List;
import kr.co.teeq.api.support.core.constant.BugReportSource;

public record BugReportCreateRequest(
    @NotNull(message = "제보 출처를 입력해 주세요.")
    @Schema(description = "제보 출처. 로그는 DEVELOPER_CONSOLE일 때만 보낸다", example = "USER")
    BugReportSource source,

    @NotBlank(message = "제보 내용을 입력해 주세요.")
    @Size(max = 2000, message = "제보 내용은 2000자 이하여야 합니다.")
    @Schema(description = "제보 내용(1~2000자)", example = "통화 화면에서 앱이 멈춰요")
    String content,

    @NotNull(message = "환경 정보를 입력해 주세요.")
    @Valid
    BugReportEnvironmentRequest environment,

    @Size(max = 100, message = "에러 로그는 100개 이하여야 합니다.")
    @Valid
    @Schema(description = "에러 로그(오래된 것부터). DEVELOPER_CONSOLE일 때만")
    List<BugReportErrorLogRequest> errorLogs,

    @Size(max = 100, message = "네트워크 기록은 100개 이하여야 합니다.")
    @Valid
    @Schema(description = "네트워크 기록(오래된 것부터). DEVELOPER_CONSOLE일 때만")
    List<BugReportNetworkLogRequest> networkLogs,

    @PositiveOrZero(message = "제외된 에러 로그 수는 0 이상이어야 합니다.")
    @Schema(description = "용량·개수 제한으로 첨부하지 못한 에러 로그 수")
    Integer omittedErrorLogCount,

    @PositiveOrZero(message = "제외된 네트워크 기록 수는 0 이상이어야 합니다.")
    @Schema(description = "용량·개수 제한으로 첨부하지 못한 네트워크 기록 수")
    Integer omittedNetworkLogCount
) {

    // Jackson 3은 primitive 필드가 빠지면 요청을 거부하므로 wrapper로 받고 없으면 0으로 본다
    public BugReportCreateRequest {
        omittedErrorLogCount = omittedErrorLogCount == null ? 0 : omittedErrorLogCount;
        omittedNetworkLogCount = omittedNetworkLogCount == null ? 0 : omittedNetworkLogCount;
    }

}
