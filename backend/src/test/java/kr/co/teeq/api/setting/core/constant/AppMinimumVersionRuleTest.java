package kr.co.teeq.api.setting.core.constant;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

class AppMinimumVersionRuleTest {

    @ParameterizedTest
    @ValueSource(strings = {"0.0.0", "1.2.3"})
    void validate_validValue_passes(String raw) {
        assertThatCode(() -> AppMinimumVersionRule.validate(raw)).doesNotThrowAnyException();
    }

    @ParameterizedTest
    @ValueSource(strings = {"1.2", "v1.2.3", ""})
    void validate_invalidValue_throwsInvalidSettingValue(String raw) {
        assertThatThrownBy(() -> AppMinimumVersionRule.validate(raw))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.INVALID_SETTING_VALUE));
    }

}
