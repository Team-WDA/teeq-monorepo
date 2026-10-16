package kr.teeq.api.call.core.entity;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.Instant;
import java.util.UUID;
import kr.teeq.api.call.core.constant.CallStatus;
import kr.teeq.api.common.core.exception.CustomException;
import kr.teeq.api.common.core.exception.ErrorCode;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class CallHistoryTest {

    private static final Instant STARTED_AT = Instant.parse("2026-10-16T03:00:00Z");
    private static final Instant ENDED_AT = Instant.parse("2026-10-16T03:05:00Z");

    private CallHistory pending() {
        return CallHistory.pending(UUID.randomUUID(), STARTED_AT);
    }

    private CallHistory inProgress() {
        CallHistory callHistory = pending();
        callHistory.activate("session-1");
        return callHistory;
    }

    @Test
    @DisplayName("pending은 PENDING 상태, 0초, 세션 ID 없음으로 만든다")
    void pendingInitialState() {
        UUID memberId = UUID.randomUUID();

        CallHistory callHistory = CallHistory.pending(memberId, STARTED_AT);

        assertThat(callHistory.getMemberId()).isEqualTo(memberId);
        assertThat(callHistory.getStartedAt()).isEqualTo(STARTED_AT);
        assertThat(callHistory.getStatus()).isEqualTo(CallStatus.PENDING);
        assertThat(callHistory.getDurationSeconds()).isZero();
        assertThat(callHistory.getCallSessionId()).isNull();
        assertThat(callHistory.getEndedAt()).isNull();
    }

    @Test
    @DisplayName("activate는 IN_PROGRESS로 바꾸고 세션 ID를 저장한다")
    void activate() {
        CallHistory callHistory = pending();

        callHistory.activate("session-1");

        assertThat(callHistory.getStatus()).isEqualTo(CallStatus.IN_PROGRESS);
        assertThat(callHistory.getCallSessionId()).isEqualTo("session-1");
    }

    @Test
    @DisplayName("fail은 PENDING을 FAILED로 바꾸고 진행 중이 아니게 된다")
    void fail() {
        CallHistory callHistory = pending();

        callHistory.fail();

        assertThat(callHistory.getStatus()).isEqualTo(CallStatus.FAILED);
    }

    @Test
    @DisplayName("end는 IN_PROGRESS를 ENDED로 바꾸고 사용 시간과 종료 시각을 저장한다")
    void endFromInProgress() {
        CallHistory callHistory = inProgress();

        callHistory.end(300, ENDED_AT);

        assertThat(callHistory.getStatus()).isEqualTo(CallStatus.ENDED);
        assertThat(callHistory.getDurationSeconds()).isEqualTo(300);
        assertThat(callHistory.getEndedAt()).isEqualTo(ENDED_AT);
    }

    @Test
    @DisplayName("end는 EXPIRED도 ENDED로 덮어쓴다")
    void endFromExpired() {
        CallHistory callHistory = inProgress();
        callHistory.expire();

        callHistory.end(120, ENDED_AT);

        assertThat(callHistory.getStatus()).isEqualTo(CallStatus.ENDED);
        assertThat(callHistory.getDurationSeconds()).isEqualTo(120);
        assertThat(callHistory.getEndedAt()).isEqualTo(ENDED_AT);
    }

    @Test
    @DisplayName("expire는 EXPIRED로 바꾸고 사용 시간을 0초로 둔다")
    void expire() {
        CallHistory callHistory = inProgress();

        callHistory.expire();

        assertThat(callHistory.getStatus()).isEqualTo(CallStatus.EXPIRED);
        assertThat(callHistory.getDurationSeconds()).isZero();
    }

    @Test
    @DisplayName("PENDING도 expire할 수 있다")
    void expireFromPending() {
        CallHistory callHistory = pending();

        callHistory.expire();

        assertThat(callHistory.getStatus()).isEqualTo(CallStatus.EXPIRED);
    }

    @Test
    @DisplayName("ENDED에 end, expire, activate, fail을 호출하면 STATE_CONFLICT")
    void endedRejectsTransitions() {
        CallHistory callHistory = inProgress();
        callHistory.end(300, ENDED_AT);

        assertStateConflict(() -> callHistory.end(10, ENDED_AT));
        assertStateConflict(callHistory::expire);
        assertStateConflict(() -> callHistory.activate("session-2"));
        assertStateConflict(callHistory::fail);
        assertThat(callHistory.getDurationSeconds()).isEqualTo(300);
    }

    @Test
    @DisplayName("IN_PROGRESS는 fail할 수 없고 PENDING은 end할 수 없다")
    void invalidTransitions() {
        assertStateConflict(() -> inProgress().fail());
        assertStateConflict(() -> pending().end(10, ENDED_AT));
    }

    private void assertStateConflict(Runnable action) {
        assertThatThrownBy(action::run)
            .isInstanceOf(CustomException.class)
            .extracting(exception -> ((CustomException) exception).getErrorCode())
            .isEqualTo(ErrorCode.STATE_CONFLICT);
    }

}
