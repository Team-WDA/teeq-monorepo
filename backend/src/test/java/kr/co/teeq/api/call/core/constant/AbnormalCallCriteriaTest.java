package kr.co.teeq.api.call.core.constant;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class AbnormalCallCriteriaTest {

    @Test
    void 상태_이름은_FAILED와_EXPIRED다() {
        assertThat(AbnormalCallCriteria.statusNames()).containsExactly("FAILED", "EXPIRED");
    }

    @Test
    void 종료_사유_이름은_AGENT_ERROR와_DISPATCH_FAILED다() {
        assertThat(AbnormalCallCriteria.endedEndReasonNames()).containsExactly("AGENT_ERROR", "DISPATCH_FAILED");
    }

    @Test
    void 비정상_상태에_ENDED는_없다() {
        assertThat(AbnormalCallCriteria.STATUSES).doesNotContain(CallStatus.ENDED);
    }

}
