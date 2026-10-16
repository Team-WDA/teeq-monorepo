package kr.teeq.api.call.application.dto.request;

import static org.assertj.core.api.Assertions.assertThat;

import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import java.time.Instant;
import java.util.Set;
import org.junit.jupiter.api.Test;

class CallUsageReportRequestValidationTest {

    private static final Validator VALIDATOR = Validation.buildDefaultValidatorFactory().getValidator();
    private static final Instant ENDED_AT = Instant.parse("2026-10-16T03:05:00Z");

    private Set<ConstraintViolation<CallUsageReportRequest>> validate(Integer usedSeconds, Instant endedAt) {
        return VALIDATOR.validate(new CallUsageReportRequest(usedSeconds, endedAt));
    }

    private void assertSingleViolation(Set<ConstraintViolation<CallUsageReportRequest>> violations,
        String propertyName) {
        assertThat(violations)
            .extracting(violation -> violation.getPropertyPath().toString())
            .containsExactly(propertyName);
    }

    @Test
    void validRequest_hasNoViolations() {
        assertThat(validate(300, ENDED_AT)).isEmpty();
    }

    @Test
    void usedSecondsZero_isAllowed() {
        assertThat(validate(0, ENDED_AT)).isEmpty();
    }

    @Test
    void negativeUsedSeconds_isRejected() {
        assertSingleViolation(validate(-1, ENDED_AT), "usedSeconds");
    }

    @Test
    void nullUsedSeconds_isRejected() {
        assertSingleViolation(validate(null, ENDED_AT), "usedSeconds");
    }

    @Test
    void nullEndedAt_isRejected() {
        assertSingleViolation(validate(300, null), "endedAt");
    }

}
