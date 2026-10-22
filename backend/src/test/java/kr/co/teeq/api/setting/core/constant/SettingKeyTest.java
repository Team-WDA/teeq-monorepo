package kr.co.teeq.api.setting.core.constant;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import org.junit.jupiter.api.Test;

class SettingKeyTest {

    @Test
    void validate_greetingDefaultValues_pass() {
        assertThat(SettingKey.GREETING_DEFAULT_MESSAGE_CASUAL.defaultValue())
            .isEqualTo("{호칭},\n오늘 하루 어땠어?\n무슨 일 있었는지 궁금한데...");
        assertThat(SettingKey.GREETING_DEFAULT_MESSAGE_POLITE.defaultValue())
            .isEqualTo("{호칭},\n오늘 하루 어땠어요?\n무슨 일 있었는지 궁금해요.");
        SettingKey casual = SettingKey.GREETING_DEFAULT_MESSAGE_CASUAL;
        SettingKey polite = SettingKey.GREETING_DEFAULT_MESSAGE_POLITE;
        assertThatCode(() -> {
            casual.validate(casual.defaultValue());
            polite.validate(polite.defaultValue());
        }).doesNotThrowAnyException();
    }

    @Test
    void validate_greetingWithoutPlaceholder_throws() {
        assertThatThrownBy(() -> SettingKey.GREETING_DEFAULT_MESSAGE_POLITE.validate("오늘 하루 어땠어요?"))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.INVALID_SETTING_VALUE));
    }

    @Test
    void validate_keyWithoutExtraValidator_onlyChecksValueType() {
        assertThatCode(() -> SettingKey.CALL_MAX_SECONDS_PER_DAY.validate("100")).doesNotThrowAnyException();
        assertThatThrownBy(() -> SettingKey.CALL_MAX_SECONDS_PER_DAY.validate("0"))
            .isInstanceOf(CustomException.class);
    }

    @Test
    void validate_appMinimumVersionKey_checksVersionFormat() {
        assertThatThrownBy(() -> SettingKey.APP_MIN_VERSION_ANDROID.validate("1.2"))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.INVALID_SETTING_VALUE));
        assertThatCode(() -> SettingKey.APP_MIN_VERSION_IOS.validate("1.2.3")).doesNotThrowAnyException();
    }

    @Test
    void validate_appStoreUrlKey_onlyRejectsBlank() {
        assertThatCode(() -> SettingKey.APP_STORE_URL_IOS.validate("아무 문자열")).doesNotThrowAnyException();
        assertThatThrownBy(() -> SettingKey.APP_STORE_URL_IOS.validate("  "))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.INVALID_SETTING_VALUE));
    }

}
