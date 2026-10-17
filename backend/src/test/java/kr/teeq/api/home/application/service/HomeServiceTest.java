package kr.teeq.api.home.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verifyNoInteractions;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kr.teeq.api.aicharacter.application.dto.response.AiCharacterResponse;
import kr.teeq.api.aicharacter.application.service.AiCharacterService;
import kr.teeq.api.call.application.dto.response.CallLimitStatusResponse;
import kr.teeq.api.call.application.service.CallLimitService;
import kr.teeq.api.common.core.exception.CustomException;
import kr.teeq.api.common.core.exception.ErrorCode;
import kr.teeq.api.feedback.application.dto.response.PendingFeedbackResponse;
import kr.teeq.api.feedback.application.service.CallFeedbackService;
import kr.teeq.api.home.application.dto.response.HomeResponse;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class HomeServiceTest {

    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final AiCharacterResponse CHARACTER =
        new AiCharacterResponse("티큐", 3, List.of("다정한", "차분한", "든든한"));
    private static final CallLimitStatusResponse CALL_LIMIT = new CallLimitStatusResponse(300, 1500, 1200, true);

    @Mock
    private AiCharacterService aiCharacterService;

    @Mock
    private CallLimitService callLimitService;

    @Mock
    private CallFeedbackService callFeedbackService;

    @Mock
    private DailyGreetingService dailyGreetingService;

    @InjectMocks
    private HomeService homeService;

    @Test
    void 협력자_결과를_그대로_조립한다() {
        PendingFeedbackResponse pendingFeedback = new PendingFeedbackResponse("call-session-1", 3);
        given(aiCharacterService.get(MEMBER_ID)).willReturn(CHARACTER);
        given(dailyGreetingService.getOrCreate(MEMBER_ID, "소연", CHARACTER)).willReturn("소연아,\n오늘 어땠어?");
        given(callLimitService.getTodayStatus(MEMBER_ID)).willReturn(CALL_LIMIT);
        given(callFeedbackService.findPendingFeedback(MEMBER_ID)).willReturn(Optional.of(pendingFeedback));

        HomeResponse response = homeService.getHome(MEMBER_ID, "소연");

        assertThat(response).isEqualTo(new HomeResponse("티큐", List.of("다정한", "차분한", "든든한"),
            "소연아,\n오늘 어땠어?", CALL_LIMIT, pendingFeedback));
    }

    @Test
    void 대기_피드백이_없으면_pendingFeedback은_null이다() {
        given(aiCharacterService.get(MEMBER_ID)).willReturn(CHARACTER);
        given(dailyGreetingService.getOrCreate(MEMBER_ID, "소연", CHARACTER)).willReturn("안녕");
        given(callLimitService.getTodayStatus(MEMBER_ID)).willReturn(CALL_LIMIT);
        given(callFeedbackService.findPendingFeedback(MEMBER_ID)).willReturn(Optional.empty());

        assertThat(homeService.getHome(MEMBER_ID, "소연").pendingFeedback()).isNull();
    }

    @Test
    void 캐릭터가_없으면_예외가_전파되고_이후_협력자는_호출하지_않는다() {
        given(aiCharacterService.get(MEMBER_ID)).willThrow(new CustomException(ErrorCode.AI_CHARACTER_NOT_FOUND));

        assertThatThrownBy(() -> homeService.getHome(MEMBER_ID, "소연"))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.AI_CHARACTER_NOT_FOUND));
        verifyNoInteractions(dailyGreetingService, callLimitService, callFeedbackService);
    }

}
