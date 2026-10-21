package kr.co.teeq.api.call.core.constant;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.stream.Stream;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

class CallLimitDecisionTest {

    static Stream<Arguments> cases() {
        return Stream.of(
            Arguments.of(1200L, 900L, 5000L, 900L, LimitKind.PER_DAY),
            Arguments.of(1200L, 5000L, 800L, 800L, LimitKind.WHOLE_SERVICE),
            Arguments.of(600L, 900L, 5000L, 600L, LimitKind.PER_CALL),
            Arguments.of(900L, 900L, 5000L, 900L, LimitKind.PER_DAY),
            Arguments.of(800L, 5000L, 800L, 800L, LimitKind.WHOLE_SERVICE),
            Arguments.of(900L, 900L, 900L, 900L, LimitKind.PER_DAY),
            Arguments.of(600L, 600L, 5000L, 600L, LimitKind.PER_DAY)
        );
    }

    @ParameterizedTest
    @MethodSource("cases")
    void of_picksSmallestValueAndBreaksTiesByPriority(long perCallSeconds, long perDayRemainingSeconds,
        long wholeServiceRemainingSeconds, long expectedSeconds, LimitKind expectedKind) {
        CallLimitDecision decision = CallLimitDecision.of(perCallSeconds, perDayRemainingSeconds,
            wholeServiceRemainingSeconds);

        assertThat(decision).isEqualTo(new CallLimitDecision(expectedSeconds, expectedKind));
    }

}
