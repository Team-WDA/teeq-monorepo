package kr.co.teeq.api.onboarding.application.handler;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.BDDMockito.given;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.common.core.constant.CharacterType;
import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.event.MemberDeletedEvent;
import kr.co.teeq.api.onboarding.core.constant.OnboardingOption;
import kr.co.teeq.api.onboarding.core.constant.OnboardingQuestion;
import kr.co.teeq.api.onboarding.core.entity.OnboardingAnswer;
import kr.co.teeq.api.onboarding.core.entity.OnboardingSubmission;
import kr.co.teeq.api.onboarding.core.repository.OnboardingAnswerRepository;
import kr.co.teeq.api.onboarding.core.repository.OnboardingSubmissionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class OnboardingMemberDeletionHandlerTest {

    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final Instant NOW = Instant.parse("2026-10-22T03:00:00Z");

    @Mock
    private OnboardingAnswerRepository onboardingAnswerRepository;

    @Mock
    private OnboardingSubmissionRepository onboardingSubmissionRepository;

    private OnboardingMemberDeletionHandler handler;

    @BeforeEach
    void setUp() {
        Clock clock = Clock.fixed(NOW, ZoneOffset.UTC);
        handler = new OnboardingMemberDeletionHandler(onboardingAnswerRepository, onboardingSubmissionRepository,
            clock);
    }

    @Test
    void handle_softDeletesAnswersAndSubmissions() {
        Member member = Member.createSocialMember(LoginType.APPLE, "social-id", "a@b.c", "소연");
        OnboardingSubmission submission = OnboardingSubmission.of(member, "persona-id", CharacterType.CHARACTER_1,
            List.of("태그1", "태그2", "태그3"));
        OnboardingAnswer firstAnswer = OnboardingAnswer.of(member, submission, OnboardingQuestion.RELATIONSHIP,
            OnboardingOption.RELATIONSHIP_CLOSE_FRIEND);
        OnboardingAnswer secondAnswer = OnboardingAnswer.of(member, submission, OnboardingQuestion.PERSONALITY,
            OnboardingOption.PERSONALITY_MOOD_MAKER);
        given(onboardingAnswerRepository.findByMemberIdAndDeletedFalse(MEMBER_ID))
            .willReturn(List.of(firstAnswer, secondAnswer));
        given(onboardingSubmissionRepository.findByMemberIdAndDeletedFalse(MEMBER_ID))
            .willReturn(List.of(submission));

        handler.handle(new MemberDeletedEvent(MEMBER_ID));

        assertThat(List.of(firstAnswer, secondAnswer)).allSatisfy(answer -> {
            assertThat(answer.isDeleted()).isTrue();
            assertThat(answer.getDeletedAt()).isEqualTo(NOW);
        });
        assertThat(submission.isDeleted()).isTrue();
        assertThat(submission.getDeletedAt()).isEqualTo(NOW);
    }

}
