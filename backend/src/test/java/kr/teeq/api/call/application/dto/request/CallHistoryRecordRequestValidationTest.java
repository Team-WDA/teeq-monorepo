package kr.teeq.api.call.application.dto.request;

import static org.assertj.core.api.Assertions.assertThat;

import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import java.time.Instant;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

class CallHistoryRecordRequestValidationTest {

    private static final Validator VALIDATOR = Validation.buildDefaultValidatorFactory().getValidator();
    private static final Instant STARTED_AT = Instant.parse("2026-10-16T03:00:00Z");

    private Set<ConstraintViolation<CallHistoryRecordRequest>> validate(String callSessionId, UUID memberId,
        Instant startedAt, Integer durationSeconds) {
        return VALIDATOR.validate(new CallHistoryRecordRequest(callSessionId, memberId, startedAt, durationSeconds));
    }

    private void assertSingleViolation(Set<ConstraintViolation<CallHistoryRecordRequest>> violations,
        String propertyName) {
        assertThat(violations)
            .extracting(violation -> violation.getPropertyPath().toString())
            .containsExactly(propertyName);
    }

    @Test
    void validRequest_hasNoViolations() {
        assertThat(validate("session-1", UUID.randomUUID(), STARTED_AT, 300)).isEmpty();
    }

    @Test
    void durationZero_isAllowed() {
        assertThat(validate("session-1", UUID.randomUUID(), STARTED_AT, 0)).isEmpty();
    }

    @Test
    void sessionIdOf64Characters_isAllowed() {
        assertThat(validate("a".repeat(64), UUID.randomUUID(), STARTED_AT, 300)).isEmpty();
    }

    @Test
    void negativeDuration_isRejected() {
        assertSingleViolation(validate("session-1", UUID.randomUUID(), STARTED_AT, -1), "durationSeconds");
    }

    @ParameterizedTest
    @ValueSource(strings = {"", " "})
    void blankSessionId_isRejected(String callSessionId) {
        assertSingleViolation(validate(callSessionId, UUID.randomUUID(), STARTED_AT, 300), "callSessionId");
    }

    @Test
    void nullSessionId_isRejected() {
        assertSingleViolation(validate(null, UUID.randomUUID(), STARTED_AT, 300), "callSessionId");
    }

    @Test
    void sessionIdOf65Characters_isRejected() {
        assertSingleViolation(validate("a".repeat(65), UUID.randomUUID(), STARTED_AT, 300), "callSessionId");
    }

    @Test
    void nullMemberId_isRejected() {
        assertSingleViolation(validate("session-1", null, STARTED_AT, 300), "memberId");
    }

    @Test
    void nullStartedAt_isRejected() {
        assertSingleViolation(validate("session-1", UUID.randomUUID(), null, 300), "startedAt");
    }

    @Test
    void nullDuration_isRejected() {
        assertSingleViolation(validate("session-1", UUID.randomUUID(), STARTED_AT, null), "durationSeconds");
    }

}
