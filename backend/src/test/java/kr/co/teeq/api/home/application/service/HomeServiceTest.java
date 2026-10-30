package kr.co.teeq.api.home.application.service;

import kr.co.teeq.api.common.core.constant.CharacterType;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verifyNoInteractions;

import java.util.List;
import java.util.Optional;
import kr.co.teeq.api.aicharacter.application.dto.response.AiCharacterResponse;
import kr.co.teeq.api.aicharacter.application.service.AiCharacterService;
import kr.co.teeq.api.call.application.dto.response.CallLimitStatusResponse;
import kr.co.teeq.api.call.application.service.CallLimitService;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.feedback.application.dto.response.PendingFeedbackResponse;
import kr.co.teeq.api.feedback.application.service.CallFeedbackService;
import kr.co.teeq.api.home.application.dto.response.HomeResponse;
import kr.co.teeq.api.home.core.constant.CharacterMood;
import kr.co.teeq.api.home.core.port.GreetingResult;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.onboarding.application.service.OnboardingPersonaService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class HomeServiceTest {

    private static final AiCharacterResponse CHARACTER =
        new AiCharacterResponse("티큐", CharacterType.CHARACTER_3, List.of("다정한", "차분한", "든든한"));
    private static final String PERSONA_ID = "persona-1";
    private static final CallLimitStatusResponse CALL_LIMIT = new CallLimitStatusResponse(300, 1500, 1200, true);

    @Mock
    private Member member;

    @Mock
    private AiCharacterService aiCharacterService;

    @Mock
    private CallLimitService callLimitService;

    @Mock
    private CallFeedbackService callFeedbackService;

    @Mock
    private OnboardingPersonaService onboardingPersonaService;

    @Mock
    private GreetingService greetingService;

    @InjectMocks
    private HomeService homeService;

    @Test
    void 협력자_결과를_그대로_조립한다() {
        PendingFeedbackResponse pendingFeedback = new PendingFeedbackResponse("call-session-1", 3);
        given(aiCharacterService.get(member)).willReturn(CHARACTER);
        given(onboardingPersonaService.getCurrentPersonaId(member)).willReturn(PERSONA_ID);
        given(greetingService.greet(member, CHARACTER, PERSONA_ID))
            .willReturn(new GreetingResult("소연아,\n오늘 어땠어?", CharacterMood.CURIOUS));
        given(callLimitService.getTodayStatus(member)).willReturn(CALL_LIMIT);
        given(callFeedbackService.findPendingFeedback(member)).willReturn(Optional.of(pendingFeedback));

        HomeResponse response = homeService.getHome(member);

        assertThat(response).isEqualTo(new HomeResponse("티큐", CharacterType.CHARACTER_3, CharacterMood.CURIOUS,
            List.of("다정한", "차분한", "든든한"), "소연아,\n오늘 어땠어?", CALL_LIMIT, pendingFeedback));
    }

    @Test
    void 대기_피드백이_없으면_pendingFeedback은_null이다() {
        given(aiCharacterService.get(member)).willReturn(CHARACTER);
        given(onboardingPersonaService.getCurrentPersonaId(member)).willReturn(PERSONA_ID);
        given(greetingService.greet(member, CHARACTER, PERSONA_ID))
            .willReturn(new GreetingResult("안녕", CharacterMood.WELCOME));
        given(callLimitService.getTodayStatus(member)).willReturn(CALL_LIMIT);
        given(callFeedbackService.findPendingFeedback(member)).willReturn(Optional.empty());

        assertThat(homeService.getHome(member).pendingFeedback()).isNull();
    }

    @Test
    void 캐릭터가_없으면_예외가_전파되고_이후_협력자는_호출하지_않는다() {
        given(aiCharacterService.get(member)).willThrow(new CustomException(ErrorCode.AI_CHARACTER_NOT_FOUND));

        assertThatThrownBy(() -> homeService.getHome(member))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.AI_CHARACTER_NOT_FOUND));
        verifyNoInteractions(onboardingPersonaService, greetingService, callLimitService, callFeedbackService);
    }

    @Test
    void 온보딩_제출이_없으면_AI_CHARACTER_NOT_FOUND가_전파되고_인사말을_만들지_않는다() {
        given(aiCharacterService.get(member)).willReturn(CHARACTER);
        given(onboardingPersonaService.getCurrentPersonaId(member))
            .willThrow(new CustomException(ErrorCode.AI_CHARACTER_NOT_FOUND));

        assertThatThrownBy(() -> homeService.getHome(member))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.AI_CHARACTER_NOT_FOUND));
        verifyNoInteractions(greetingService, callLimitService, callFeedbackService);
    }

}
