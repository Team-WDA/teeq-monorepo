package kr.co.teeq.api.admin.application.view;

import static org.assertj.core.api.Assertions.assertThat;

import kr.co.teeq.api.call.core.constant.CallStatus;
import kr.co.teeq.api.call.core.constant.EndReason;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;

class CallDisplayLabelTest {

    @ParameterizedTest
    @EnumSource(CallStatus.class)
    void status_returnsNonBlankLabelForEveryValue(CallStatus status) {
        assertThat(CallDisplayLabel.status(status)).isNotBlank();
    }

    @ParameterizedTest
    @EnumSource(EndReason.class)
    void endReason_returnsNonBlankLabelForEveryValue(EndReason endReason) {
        assertThat(CallDisplayLabel.endReason(endReason)).isNotBlank();
    }

    @Test
    void endReason_null_returnsDash() {
        assertThat(CallDisplayLabel.endReason(null)).isEqualTo("-");
    }

}
