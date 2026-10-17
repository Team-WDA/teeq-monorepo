package kr.teeq.api.setting.core.constant;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import kr.teeq.api.common.core.exception.CustomException;
import kr.teeq.api.common.core.exception.ErrorCode;
import org.junit.jupiter.api.Test;

class GreetingMessageRuleTest {

    private void assertInvalidTemplate(String raw) {
        assertThatThrownBy(() -> GreetingMessageRule.validateTemplate(raw))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.INVALID_SETTING_VALUE));
    }

    @Test
    void isValidMessage_nullEmptyOrBlank_returnsFalse() {
        assertThat(GreetingMessageRule.isValidMessage(null)).isFalse();
        assertThat(GreetingMessageRule.isValidMessage("")).isFalse();
        assertThat(GreetingMessageRule.isValidMessage("   ")).isFalse();
    }

    @Test
    void isValidMessage_bodyExactlyMaxLength_returnsTrue() {
        assertThat(GreetingMessageRule.isValidMessage("가".repeat(45))).isTrue();
    }

    @Test
    void isValidMessage_bodyOverMaxLength_returnsFalse() {
        assertThat(GreetingMessageRule.isValidMessage("가".repeat(46))).isFalse();
    }

    @Test
    void isValidMessage_lineBreaksExcludedFromBodyLength_returnsTrue() {
        assertThat(GreetingMessageRule.isValidMessage("가".repeat(15) + "\n" + "나".repeat(15) + "\n"
            + "다".repeat(15))).isTrue();
    }

    @Test
    void isValidMessage_storedLengthOverMax_returnsFalse() {
        // 본문은 10자지만 줄바꿈이 많아 전체가 201자
        String message = "가".repeat(10) + "\n".repeat(191);

        assertThat(message).hasSize(201);
        assertThat(GreetingMessageRule.isValidMessage(message)).isFalse();
    }

    @Test
    void isValidMessage_controlCharacter_returnsFalse() {
        assertThat(GreetingMessageRule.isValidMessage("안녕\u0000")).isFalse();
    }

    @Test
    void isValidMessage_withLineBreaks_returnsTrue() {
        assertThat(GreetingMessageRule.isValidMessage("안녕,\n오늘 하루 어땠어?")).isTrue();
    }

    @Test
    void validateTemplate_valid_passes() {
        assertThatCode(() -> GreetingMessageRule.validateTemplate("{호칭},\n오늘 하루 어땠어?"))
            .doesNotThrowAnyException();
    }

    @Test
    void validateTemplate_withoutPlaceholder_throws() {
        assertInvalidTemplate("오늘 하루 어땠어?");
    }

    @Test
    void validateTemplate_placeholderTwice_throws() {
        assertInvalidTemplate("{호칭}, {호칭}");
    }

    @Test
    void validateTemplate_blank_throws() {
        assertInvalidTemplate(" ");
        assertInvalidTemplate(null);
    }

    @Test
    void validateTemplate_overMaxLengthAfterSubstitution_throws() {
        // 치환 후 12 + 34 = 46자
        assertInvalidTemplate("{호칭}" + "가".repeat(34));
    }

    @Test
    void validateTemplate_maxLengthAfterSubstitution_passes() {
        assertThatCode(() -> GreetingMessageRule.validateTemplate("{호칭}" + "가".repeat(33)))
            .doesNotThrowAnyException();
    }

}
