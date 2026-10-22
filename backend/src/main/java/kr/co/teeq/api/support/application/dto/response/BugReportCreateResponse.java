package kr.co.teeq.api.support.application.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.UUID;

public record BugReportCreateResponse(
    @Schema(description = "저장된 제보 id")
    UUID bugReportId
) {

}
