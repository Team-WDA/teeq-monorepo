package kr.co.teeq.api.onboarding.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.mock;

import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.onboarding.core.entity.OnboardingSubmission;
import kr.co.teeq.api.onboarding.core.repository.OnboardingSubmissionRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class OnboardingPersonaServiceTest {

    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");

    @Mock
    private OnboardingSubmissionRepository onboardingSubmissionRepository;

    @InjectMocks
    private OnboardingPersonaService onboardingPersonaService;

    @Test
    void 가장_최근_제출의_personaId를_돌려준다() {
        Member member = mock(Member.class);
        given(member.getId()).willReturn(MEMBER_ID);
        OnboardingSubmission latestSubmission = mock(OnboardingSubmission.class);
        given(latestSubmission.getPersonaId()).willReturn("persona-latest");
        given(onboardingSubmissionRepository.findFirstByMemberIdAndDeletedFalseOrderByCreatedAtDescIdDesc(MEMBER_ID))
                .willReturn(Optional.of(latestSubmission));

        assertThat(onboardingPersonaService.getCurrentPersonaId(member)).isEqualTo("persona-latest");
    }

    @Test
    void 제출이_없으면_AI_CHARACTER_NOT_FOUND() {
        Member member = mock(Member.class);
        given(member.getId()).willReturn(MEMBER_ID);
        given(onboardingSubmissionRepository.findFirstByMemberIdAndDeletedFalseOrderByCreatedAtDescIdDesc(MEMBER_ID))
                .willReturn(Optional.empty());

        assertThatThrownBy(() -> onboardingPersonaService.getCurrentPersonaId(member))
                .isInstanceOf(CustomException.class)
                .extracting(exception -> ((CustomException) exception).getErrorCode())
                .isEqualTo(ErrorCode.AI_CHARACTER_NOT_FOUND);
    }
}
