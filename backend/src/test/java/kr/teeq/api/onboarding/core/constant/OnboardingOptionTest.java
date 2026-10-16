package kr.teeq.api.onboarding.core.constant;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.Arrays;
import java.util.List;
import org.junit.jupiter.api.Test;

class OnboardingOptionTest {

    @Test
    void optionCountPerQuestion_followsDesign() {
        assertThat(OnboardingOption.of(OnboardingQuestion.RELATIONSHIP)).hasSize(4);
        assertThat(OnboardingOption.of(OnboardingQuestion.PERSONALITY)).hasSize(4);
        assertThat(OnboardingOption.of(OnboardingQuestion.SPEECH_STYLE)).hasSize(3);
        assertThat(OnboardingOption.of(OnboardingQuestion.VOICE_TONE)).hasSize(4);
        assertThat(OnboardingOption.of(OnboardingQuestion.ADVICE_STYLE)).hasSize(4);
        assertThat(OnboardingOption.of(OnboardingQuestion.CONVERSATION_LEAD)).hasSize(3);
        assertThat(OnboardingOption.of(OnboardingQuestion.AVOID_BEHAVIOR)).hasSize(5);
        assertThat(OnboardingOption.values()).hasSize(27);
    }

    @Test
    void everyOption_nameStartsWithQuestionName() {
        Arrays.stream(OnboardingOption.values())
            .forEach(option -> assertThat(option.name()).startsWith(option.question().name() + "_"));
    }

    @Test
    void of_returnsOptionsInDeclarationOrder() {
        List<OnboardingOption> options = OnboardingOption.of(OnboardingQuestion.CONVERSATION_LEAD);

        assertThat(options).containsExactly(
            OnboardingOption.CONVERSATION_LEAD_LISTENER,
            OnboardingOption.CONVERSATION_LEAD_BALANCED,
            OnboardingOption.CONVERSATION_LEAD_LEADER);
    }

    @Test
    void selectionRange_avoidBehaviorIsMultipleAndOthersAreSingle() {
        assertThat(OnboardingQuestion.AVOID_BEHAVIOR.minSelections()).isEqualTo(1);
        assertThat(OnboardingQuestion.AVOID_BEHAVIOR.maxSelections()).isEqualTo(5);
        Arrays.stream(OnboardingQuestion.values())
            .filter(question -> question != OnboardingQuestion.AVOID_BEHAVIOR)
            .forEach(question -> {
                assertThat(question.minSelections()).isEqualTo(1);
                assertThat(question.maxSelections()).isEqualTo(1);
            });
    }

}
