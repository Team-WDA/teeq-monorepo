package kr.co.teeq.api.setting.application.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import kr.co.teeq.api.setting.core.constant.SettingKey;
import kr.co.teeq.api.setting.core.constant.SettingValueType;
import kr.co.teeq.api.setting.core.entity.SettingConfig;

public record SettingConfigResponse(
    @Schema(description = "설정 키", example = "CALL_SESSION_LIMIT_SECONDS")
    String key,

    @Schema(description = "현재 값(문자열). 저장된 값이 없으면 기본값", example = "1200")
    String value,

    @Schema(description = "값 타입", example = "INT")
    SettingValueType valueType,

    @Schema(description = "설정 설명")
    String description,

    @Schema(description = "마지막 수정 시각(ISO-8601 UTC). 저장된 값이 없어 기본값을 쓰는 중이면 null")
    Instant updatedAt
) {

    public static SettingConfigResponse of(SettingKey settingKey, SettingConfig settingConfig) {
        if (settingConfig == null) {
            return new SettingConfigResponse(settingKey.name(), settingKey.defaultValue(), settingKey.valueType(),
                settingKey.description(), null);
        }
        return new SettingConfigResponse(settingKey.name(), settingConfig.getConfigValue(), settingKey.valueType(),
            settingKey.description(), settingConfig.getUpdatedAt());
    }

}
