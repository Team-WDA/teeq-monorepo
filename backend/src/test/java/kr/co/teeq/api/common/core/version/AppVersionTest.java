package kr.co.teeq.api.common.core.version;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullSource;
import org.junit.jupiter.params.provider.ValueSource;

class AppVersionTest {

    @Test
    void parse_validValue_returnsVersion() {
        assertThat(AppVersion.parse("1.2.3")).isEqualTo(new AppVersion(1, 2, 3));
        assertThat(AppVersion.parse("1.2.3")).hasToString("1.2.3");
    }

    @Test
    void compareTo_comparesNumerically() {
        assertThat(AppVersion.parse("1.10.0")).isGreaterThan(AppVersion.parse("1.9.0"));
        assertThat(AppVersion.parse("1.2.3").compareTo(AppVersion.parse("1.2.3"))).isZero();
        assertThat(AppVersion.parse("2.0.0")).isGreaterThan(AppVersion.parse("1.99.99"));
    }

    @ParameterizedTest
    @NullSource
    @ValueSource(strings = {"", "abc", "1.2", "1.2.3.4", "1.2.3+4", "1.2.3-beta", " 1.2.3", "1.2.3 ", "01.2.3",
        "1.2.-3", "99999999999.0.0"})
    void parse_invalidValue_throwsInvalidRequest(String raw) {
        assertThatThrownBy(() -> AppVersion.parse(raw))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.INVALID_REQUEST));
    }

}
