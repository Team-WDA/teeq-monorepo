package kr.co.teeq.api.admin.application.dto.response;

import java.time.Instant;
import kr.co.teeq.api.setting.application.dto.response.SettingConfigResponse;
import kr.co.teeq.api.setting.core.constant.SettingKey;
import kr.co.teeq.api.setting.core.constant.SettingValueType;

/**
 * 서비스 설정 화면의 한 행. 기본값 비교와 입력칸 종류 판단에 필요한 값을 함께 담는다.
 */
public record AdminSettingRowResponse(
    String key,
    String value,
    SettingValueType valueType,
    String description,
    Instant updatedAt,
    String defaultValue
) {

    // 설정 응답의 키는 SettingKey 상수 이름이므로 기본값을 그대로 찾을 수 있다
    public static AdminSettingRowResponse from(SettingConfigResponse response) {
        return new AdminSettingRowResponse(response.key(), response.value(), response.valueType(),
            response.description(), response.updatedAt(), SettingKey.valueOf(response.key()).defaultValue());
    }

    public boolean usingDefaultValue() {
        return defaultValue.equals(value);
    }

    // 문자열 값(인사말 등)은 여러 줄일 수 있어 여러 줄 입력칸으로 보여 준다
    public boolean multilineValue() {
        return valueType == SettingValueType.STRING;
    }

    public boolean integerValue() {
        return valueType == SettingValueType.INT;
    }

}
