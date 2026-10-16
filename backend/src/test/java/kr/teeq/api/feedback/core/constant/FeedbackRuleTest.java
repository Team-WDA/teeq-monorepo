package kr.teeq.api.feedback.core.constant;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

class FeedbackRuleTest {

    @DisplayName("지난 통화 기억 문항은 통화 순번이 2 이상일 때만 필수다")
    @ParameterizedTest
    @CsvSource({"1,false", "2,true", "3,true", "4,true", "6,true"})
    void isPreviousCallRecallRequired(int callIndex, boolean expected) {
        assertThat(FeedbackRule.isPreviousCallRecallRequired(callIndex)).isEqualTo(expected);
    }

    @DisplayName("상세 피드백은 통화 순번이 3의 배수일 때만 초대한다")
    @ParameterizedTest
    @CsvSource({"1,false", "2,false", "3,true", "4,false", "6,true"})
    void isDetailedFeedbackInvited(int callIndex, boolean expected) {
        assertThat(FeedbackRule.isDetailedFeedbackInvited(callIndex)).isEqualTo(expected);
    }

}
