package kr.co.teeq.api.support.core.constant;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

class BugReportStatusTest {

    @ParameterizedTest
    @CsvSource({
        "RECEIVED, IN_PROGRESS, true",
        "RECEIVED, RESOLVED, true",
        "IN_PROGRESS, RECEIVED, true",
        "RESOLVED, RECEIVED, true",
        "RECEIVED, RECEIVED, false",
        "IN_PROGRESS, IN_PROGRESS, false",
        "RESOLVED, RESOLVED, false"
    })
    @DisplayName("canTransitionTo는 서로 다른 상태일 때만 true다")
    void canTransitionTo(BugReportStatus from, BugReportStatus to, boolean expected) {
        assertThat(from.canTransitionTo(to)).isEqualTo(expected);
    }

}
