package kr.co.teeq.api.support.application.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import kr.co.teeq.api.support.core.constant.BugReportPlatform;

public record BugReportEnvironmentRequest(
    @NotBlank(message = "앱 버전을 입력해 주세요.")
    @Size(max = 50, message = "앱 버전은 50자 이하여야 합니다.")
    @Schema(description = "앱 버전", example = "1.2.3")
    String appVersion,

    @NotNull(message = "플랫폼을 입력해 주세요.")
    @Schema(description = "플랫폼", example = "ANDROID")
    BugReportPlatform platform,

    @NotBlank(message = "OS 버전을 입력해 주세요.")
    @Size(max = 100, message = "OS 버전은 100자 이하여야 합니다.")
    @Schema(description = "OS 버전", example = "Android 15")
    String osVersion,

    @NotBlank(message = "기기 모델을 입력해 주세요.")
    @Size(max = 100, message = "기기 모델은 100자 이하여야 합니다.")
    @Schema(description = "기기 모델", example = "Pixel 9")
    String deviceModel
) {

}
