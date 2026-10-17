package kr.co.teeq.api.call.core.constant;

import static kr.co.teeq.api.call.core.constant.CallStatus.ENDED;
import static kr.co.teeq.api.call.core.constant.CallStatus.EXPIRED;
import static kr.co.teeq.api.call.core.constant.CallStatus.FAILED;
import static kr.co.teeq.api.call.core.constant.CallStatus.IN_PROGRESS;
import static kr.co.teeq.api.call.core.constant.CallStatus.PENDING;
import static org.assertj.core.api.Assertions.assertThat;

import java.util.Map;
import java.util.Set;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class CallStatusTest {

    private static final Map<CallStatus, Set<CallStatus>> ALLOWED = Map.of(
        PENDING, Set.of(IN_PROGRESS, FAILED, EXPIRED),
        IN_PROGRESS, Set.of(ENDED, EXPIRED),
        EXPIRED, Set.of(ENDED),
        ENDED, Set.of(),
        FAILED, Set.of());

    @Test
    @DisplayName("canTransitionTo는 허용된 전이만 true다")
    void canTransitionTo() {
        for (CallStatus from : CallStatus.values()) {
            for (CallStatus to : CallStatus.values()) {
                assertThat(from.canTransitionTo(to))
                    .as("%s -> %s", from, to)
                    .isEqualTo(ALLOWED.get(from).contains(to));
            }
        }
    }

}
