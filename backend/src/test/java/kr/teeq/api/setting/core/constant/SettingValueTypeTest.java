package kr.teeq.api.setting.core.constant;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import kr.teeq.api.common.core.exception.CustomException;
import kr.teeq.api.common.core.exception.ErrorCode;
import org.junit.jupiter.api.Test;

class SettingValueTypeTest {

    private void assertInvalid(SettingValueType valueType, String raw, Long minimum, Long maximum) {
        assertThatThrownBy(() -> valueType.validate(raw, minimum, maximum))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.INVALID_SETTING_VALUE));
    }

    @Test
    void int_withinRange_isAccepted() {
        assertThatCode(() -> SettingValueType.INT.validate("1200", 60L, 3600L)).doesNotThrowAnyException();
        assertThatCode(() -> SettingValueType.INT.validate("60", 60L, 3600L)).doesNotThrowAnyException();
        assertThatCode(() -> SettingValueType.INT.validate("3600", 60L, 3600L)).doesNotThrowAnyException();
    }

    @Test
    void int_withoutBounds_acceptsAnyNumber() {
        assertThatCode(() -> SettingValueType.INT.validate("-5", null, null)).doesNotThrowAnyException();
    }

    @Test
    void int_notANumber_isRejected() {
        assertInvalid(SettingValueType.INT, "abc", null, null);
        assertInvalid(SettingValueType.INT, "12.5", null, null);
        assertInvalid(SettingValueType.INT, "", null, null);
        assertInvalid(SettingValueType.INT, null, null, null);
    }

    @Test
    void int_outOfRange_isRejected() {
        assertInvalid(SettingValueType.INT, "59", 60L, 3600L);
        assertInvalid(SettingValueType.INT, "3601", 60L, 3600L);
    }

    @Test
    void boolean_acceptsOnlyLowercaseTrueOrFalse() {
        assertThatCode(() -> SettingValueType.BOOLEAN.validate("true", null, null)).doesNotThrowAnyException();
        assertThatCode(() -> SettingValueType.BOOLEAN.validate("false", null, null)).doesNotThrowAnyException();
        assertInvalid(SettingValueType.BOOLEAN, "TRUE", null, null);
        assertInvalid(SettingValueType.BOOLEAN, "1", null, null);
        assertInvalid(SettingValueType.BOOLEAN, "", null, null);
        assertInvalid(SettingValueType.BOOLEAN, null, null, null);
    }

    @Test
    void string_mustNotBeBlank() {
        assertThatCode(() -> SettingValueType.STRING.validate("안녕", null, null)).doesNotThrowAnyException();
        assertInvalid(SettingValueType.STRING, "  ", null, null);
        assertInvalid(SettingValueType.STRING, "", null, null);
        assertInvalid(SettingValueType.STRING, null, null, null);
    }

}
