package kr.co.teeq.api.onboarding.core.entity;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.List;
import kr.co.teeq.api.member.core.entity.Member;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class OnboardingSubmissionTest {

    @Mock
    private Member member;

    @Test
    void of_withThreeTags_exposesCharacterAndTags() {
        OnboardingSubmission submission = OnboardingSubmission.of(member, 7, List.of("a", "b", "c"));

        assertThat(submission.getMember()).isSameAs(member);
        assertThat(submission.getCharacterNumber()).isEqualTo(7);
        assertThat(submission.getPersonalityTags()).isEqualTo(List.of("a", "b", "c"));
    }

    @Test
    void of_withWrongTagCount_throwsIllegalArgumentException() {
        assertThatThrownBy(() -> OnboardingSubmission.of(member, 7, List.of("a", "b")))
                .isInstanceOf(IllegalArgumentException.class);
    }

}
