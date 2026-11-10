package kr.co.teeq.api.admin.application.view;

import static org.assertj.core.api.Assertions.assertThat;

import kr.co.teeq.api.feedback.core.constant.AwkwardMoment;
import kr.co.teeq.api.feedback.core.constant.PreviousCallRecall;
import kr.co.teeq.api.feedback.core.constant.RevisitIntention;
import kr.co.teeq.api.feedback.core.constant.StartReason;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;

class FeedbackDisplayLabelTest {

    @ParameterizedTest
    @EnumSource(RevisitIntention.class)
    void revisitIntention_returnsNonBlankLabelForEveryValue(RevisitIntention revisitIntention) {
        assertThat(FeedbackDisplayLabel.revisitIntention(revisitIntention)).isNotBlank();
    }

    @ParameterizedTest
    @EnumSource(PreviousCallRecall.class)
    void previousCallRecall_returnsNonBlankLabelForEveryValue(PreviousCallRecall previousCallRecall) {
        assertThat(FeedbackDisplayLabel.previousCallRecall(previousCallRecall)).isNotBlank();
    }

    @ParameterizedTest
    @EnumSource(AwkwardMoment.class)
    void awkwardMoment_returnsNonBlankLabelForEveryValue(AwkwardMoment awkwardMoment) {
        assertThat(FeedbackDisplayLabel.awkwardMoment(awkwardMoment)).isNotBlank();
    }

    @ParameterizedTest
    @EnumSource(StartReason.class)
    void startReason_returnsNonBlankLabelForEveryValue(StartReason startReason) {
        assertThat(FeedbackDisplayLabel.startReason(startReason)).isNotBlank();
    }

    @Test
    void fixedLabels_matchAgreedWording() {
        assertThat(FeedbackDisplayLabel.revisitIntention(RevisitIntention.YES)).isEqualTo("다시 이용하고 싶음");
        assertThat(FeedbackDisplayLabel.revisitIntention(RevisitIntention.NEUTRAL)).isEqualTo("잘 모르겠음");
        assertThat(FeedbackDisplayLabel.revisitIntention(RevisitIntention.NO)).isEqualTo("이용하고 싶지 않음");
        assertThat(FeedbackDisplayLabel.previousCallRecall(PreviousCallRecall.REMEMBERED)).isEqualTo("기억함");
        assertThat(FeedbackDisplayLabel.previousCallRecall(PreviousCallRecall.UNSURE)).isEqualTo("잘 모르겠음");
        assertThat(FeedbackDisplayLabel.previousCallRecall(PreviousCallRecall.NO)).isEqualTo("기억하지 못함");
    }

}
