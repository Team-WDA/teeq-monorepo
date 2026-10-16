package kr.teeq.api.setting.core.constant;

import java.util.Arrays;
import java.util.Optional;

/**
 * 동적 설정 키 정의. 타입, 기본값, 설명, 범위(INT)를 코드가 정한다. 키는 필요한 기능을 구현할 때 상수로 추가한다.
 * DB에 값이 없으면 기본값을 쓴다.
 */
public enum SettingKey {
    CALL_MAX_SECONDS_PER_SESSION(SettingValueType.INT, "1200", "통화 1회에 사용할 수 있는 최대 시간(초)", 1L, null),
    CALL_MAX_SECONDS_PER_DAY(SettingValueType.INT, "1800", "사용자별 하루(KST) 통화 한도(초)", 1L, null),
    CALL_MIN_START_SECONDS(SettingValueType.INT, "60", "통화를 시작하려면 남아 있어야 하는 최소 시간(초)", 1L, null);

    private final SettingValueType valueType;
    private final String defaultValue;
    private final String description;
    private final Long minimum;
    private final Long maximum;

    SettingKey(SettingValueType valueType, String defaultValue, String description, Long minimum, Long maximum) {
        this.valueType = valueType;
        this.defaultValue = defaultValue;
        this.description = description;
        this.minimum = minimum;
        this.maximum = maximum;
    }

    public static Optional<SettingKey> find(String name) {
        return Arrays.stream(values())
            .filter(settingKey -> settingKey.name().equals(name))
            .findFirst();
    }

    public SettingValueType valueType() {
        return valueType;
    }

    public String defaultValue() {
        return defaultValue;
    }

    public String description() {
        return description;
    }

    public Long minimum() {
        return minimum;
    }

    public Long maximum() {
        return maximum;
    }

}
