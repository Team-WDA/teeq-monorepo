package kr.co.teeq.api.feedback.application.dto.request;

import static org.assertj.core.api.Assertions.assertThat;

import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Set;
import kr.co.teeq.api.feedback.core.constant.AwkwardMoment;
import kr.co.teeq.api.feedback.core.constant.RevisitIntention;
import kr.co.teeq.api.feedback.core.constant.StartReason;
import org.junit.jupiter.api.Test;

class FeedbackRequestValidationTest {

    private static final Validator VALIDATOR = Validation.buildDefaultValidatorFactory().getValidator();

    private static List<String> violatedProperties(Object request) {
        Set<? extends ConstraintViolation<?>> violations = VALIDATOR.validate(request);
        return violations.stream().map(violation -> violation.getPropertyPath().toString()).sorted().toList();
    }

    private static RequiredFeedbackRequest required(Integer rating, List<AwkwardMoment> moments) {
        return new RequiredFeedbackRequest(rating, RevisitIntention.YES, null, moments);
    }

    private static DetailedFeedbackRequest detailed(Integer timingScore, String timingReason, Integer memoryScore,
        Boolean memoryNotApplicable, String freeText, List<StartReason> startReasons, String otherText) {
        return new DetailedFeedbackRequest(timingScore, timingReason, 5, null, memoryScore, null,
            memoryNotApplicable, 3, null, 2, null, 1, null, freeText, startReasons, otherText);
    }

    private static DetailedFeedbackRequest validDetailed() {
        return detailed(4, "사유", 3, false, "자유", List.of(StartReason.OTHER), "기타");
    }

    @Test
    void validRequests_haveNoViolations() {
        assertThat(violatedProperties(required(5, List.of(AwkwardMoment.NONE)))).isEmpty();
        assertThat(violatedProperties(validDetailed())).isEmpty();
    }

    @Test
    void ratingOutOfRangeOrNull_isRejected() {
        assertThat(violatedProperties(required(0, List.of(AwkwardMoment.CUT)))).containsExactly("rating");
        assertThat(violatedProperties(required(6, List.of(AwkwardMoment.CUT)))).containsExactly("rating");
        assertThat(violatedProperties(required(null, List.of(AwkwardMoment.CUT)))).containsExactly("rating");
    }

    @Test
    void emptyOrNullElementAwkwardMoments_areRejected() {
        assertThat(violatedProperties(required(3, List.of()))).containsExactly("awkwardMoments");
        assertThat(violatedProperties(required(3, null))).containsExactly("awkwardMoments");
        assertThat(violatedProperties(required(3, Arrays.asList(AwkwardMoment.CUT, null))))
            .hasSize(1).first().asString().startsWith("awkwardMoments");
    }

    @Test
    void scoreOutOfRange_isRejected() {
        assertThat(violatedProperties(detailed(0, null, 3, false, null, List.of(StartReason.NEED_TO_TALK), null)))
            .containsExactly("timingScore");
        assertThat(violatedProperties(detailed(4, null, 6, false, null, List.of(StartReason.NEED_TO_TALK), null)))
            .containsExactly("memoryScore");
    }

    @Test
    void nullMemoryScore_isAllowedByValidation() {
        assertThat(violatedProperties(detailed(4, null, null, true, null, List.of(StartReason.NEED_TO_TALK), null)))
            .isEmpty();
    }

    @Test
    void nullMemoryNotApplicable_isRejected() {
        assertThat(violatedProperties(detailed(4, null, 3, null, null, List.of(StartReason.NEED_TO_TALK), null)))
            .containsExactly("memoryNotApplicable");
    }

    @Test
    void textOverLengthLimit_isRejected() {
        assertThat(violatedProperties(detailed(4, "가".repeat(101), 3, false, null,
            List.of(StartReason.NEED_TO_TALK), null))).containsExactly("timingReason");
        assertThat(violatedProperties(detailed(4, null, 3, false, "가".repeat(1001),
            List.of(StartReason.NEED_TO_TALK), null))).containsExactly("freeText");
        assertThat(violatedProperties(detailed(4, null, 3, false, null,
            List.of(StartReason.OTHER), "가".repeat(101)))).containsExactly("startReasonOtherText");
    }

    @Test
    void textAtLengthLimit_isAllowed() {
        assertThat(violatedProperties(detailed(4, "가".repeat(100), 3, false, "가".repeat(1000),
            List.of(StartReason.OTHER), "가".repeat(100)))).isEmpty();
    }

    @Test
    void emptyStartReasons_isRejected() {
        assertThat(violatedProperties(detailed(4, null, 3, false, null, new ArrayList<>(), null)))
            .containsExactly("startReasons");
    }

}
