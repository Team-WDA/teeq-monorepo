package kr.teeq.api.setting.core.constant;

import java.util.Arrays;
import java.util.Optional;
import java.util.function.Consumer;

/**
 * 동적 설정 키 정의. 타입, 기본값, 설명, 범위(INT)를 코드가 정한다. 키는 필요한 기능을 구현할 때 상수로 추가한다.
 * DB에 값이 없으면 기본값을 쓴다.
 */
public enum SettingKey {
    CALL_MAX_SECONDS_PER_SESSION(SettingValueType.INT, "1200", "통화 1회에 사용할 수 있는 최대 시간(초)", 1L, null),
    CALL_MAX_SECONDS_PER_DAY(SettingValueType.INT, "1800", "사용자별 하루(KST) 통화 한도(초)", 1L, null),
    CALL_MAX_SECONDS_PER_MONTH_TOTAL(SettingValueType.INT, "900000", "전체 회원이 합산해 한 달(KST)에 사용할 수 있는 통화 한도(초)", 1L, null),
    CALL_MIN_START_SECONDS(SettingValueType.INT, "60", "통화를 시작하려면 남아 있어야 하는 최소 시간(초)", 1L, null),
    GREETING_DEFAULT_MESSAGE_CASUAL(SettingValueType.STRING, "{호칭},\n오늘 하루 어땠어?\n무슨 일 있었는지 궁금한데...",
        "반말 온보딩 답변 회원에게 쓰는 기본 오늘의 한마디. {호칭} 자리에 호칭이 들어간다",
        GreetingMessageRule::validateTemplate),
    GREETING_DEFAULT_MESSAGE_POLITE(SettingValueType.STRING, "{호칭},\n오늘 하루 어땠어요?\n무슨 일 있었는지 궁금해요.",
        "존댓말 온보딩 답변 회원에게 쓰는 기본 오늘의 한마디. {호칭} 자리에 호칭이 들어간다",
        GreetingMessageRule::validateTemplate);

    private final SettingValueType valueType;
    private final String defaultValue;
    private final String description;
    private final Long minimum;
    private final Long maximum;
    // 값 타입 검증 뒤에 키별로 추가하는 검증. 없으면 null
    private final Consumer<String> additionalValidator;

    SettingKey(SettingValueType valueType, String defaultValue, String description, Long minimum, Long maximum) {
        this(valueType, defaultValue, description, minimum, maximum, null);
    }

    SettingKey(SettingValueType valueType, String defaultValue, String description,
        Consumer<String> additionalValidator) {
        this(valueType, defaultValue, description, null, null, additionalValidator);
    }

    SettingKey(SettingValueType valueType, String defaultValue, String description, Long minimum, Long maximum,
        Consumer<String> additionalValidator) {
        this.valueType = valueType;
        this.additionalValidator = additionalValidator;
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

    public void validate(String raw) {
        valueType.validate(raw, minimum, maximum);
        if (additionalValidator != null) {
            additionalValidator.accept(raw);
        }
    }

}
