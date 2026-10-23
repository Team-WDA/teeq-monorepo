package kr.co.teeq.api.setting.core.constant;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullSource;
import org.junit.jupiter.params.provider.ValueSource;

class MediaBaseUrlRuleTest {

    @ParameterizedTest
    @ValueSource(strings = {"https://api.teeq.co.kr", "http://localhost:8080", "https://cdn.example.com/"})
    void validate_validValue_passes(String raw) {
        assertThatCode(() -> MediaBaseUrlRule.validate(raw)).doesNotThrowAnyException();
    }

    @ParameterizedTest
    @NullSource
    @ValueSource(strings = {"", "   ", "api.teeq.co.kr", "ftp://x.kr", "https://", "https://a b.kr",
        "https://x.kr?a=1", "https://x.kr#a", "https://user:pw@x.kr"})
    void validate_invalidValue_throws(String raw) {
        assertThatThrownBy(() -> MediaBaseUrlRule.validate(raw))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.INVALID_SETTING_VALUE));
    }

    @Test
    void settingKey_mediaBaseUrl_usesRule() {
        assertThat(SettingKey.MEDIA_BASE_URL.valueType()).isEqualTo(SettingValueType.STRING);
        assertThat(SettingKey.MEDIA_BASE_URL.defaultValue()).isEqualTo("https://d1cia1w3bdi058.cloudfront.net/prod");
        assertThatCode(() -> SettingKey.MEDIA_BASE_URL.validate(SettingKey.MEDIA_BASE_URL.defaultValue()))
            .doesNotThrowAnyException();
        assertThatThrownBy(() -> SettingKey.MEDIA_BASE_URL.validate("api.teeq.co.kr"))
            .isInstanceOf(CustomException.class);
    }

}
