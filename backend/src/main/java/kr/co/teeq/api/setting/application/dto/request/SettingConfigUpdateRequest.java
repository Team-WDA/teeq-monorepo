package kr.co.teeq.api.setting.application.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;

public record SettingConfigUpdateRequest(
    @NotBlank(message = "설정 값을 입력해 주세요.")
    @Schema(description = "새 설정 값(문자열). 키의 타입과 범위에 맞아야 한다. BOOLEAN은 `true`/`false`", example = "1200")
    String value
) {

}
