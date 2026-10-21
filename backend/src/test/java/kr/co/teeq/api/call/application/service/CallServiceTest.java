package kr.co.teeq.api.call.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.willThrow;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import kr.co.teeq.api.aicharacter.application.dto.response.AiCharacterResponse;
import kr.co.teeq.api.aicharacter.application.service.AiCharacterService;
import kr.co.teeq.api.call.application.dto.response.CallStartResponse;
import kr.co.teeq.api.call.core.constant.CallLimitDecision;
import kr.co.teeq.api.call.core.constant.LimitKind;
import kr.co.teeq.api.call.core.port.AiCallSession;
import kr.co.teeq.api.call.core.port.AiCallSessionPort;
import kr.co.teeq.api.call.core.port.AiCallSessionRequest;
import kr.co.teeq.api.common.core.constant.CharacterType;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.onboarding.application.service.OnboardingPersonaService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InOrder;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class CallServiceTest {

    private static final String PERSONA_ID = "persona-1";
    private static final String NICKNAME = "하늘";
    private static final String CHARACTER_NAME = "다온";

    private final UUID memberId = UUID.randomUUID();
    private final UUID callHistoryId = UUID.randomUUID();
    private final AiCallSessionRequest sessionRequest = new AiCallSessionRequest(
        memberId, PERSONA_ID, NICKNAME, CHARACTER_NAME, 900L, LimitKind.PER_DAY);

    @Mock
    private Member member;

    @Mock
    private CallLimitService callLimitService;

    @Mock
    private CallHistoryService callHistoryService;

    @Mock
    private OnboardingPersonaService onboardingPersonaService;

    @Mock
    private AiCharacterService aiCharacterService;

    @Mock
    private AiCallSessionPort aiCallSessionPort;

    @InjectMocks
    private CallService callService;

    private void stubStartable() {
        given(callLimitService.checkStartable(member)).willReturn(new CallLimitDecision(900L, LimitKind.PER_DAY));
        given(onboardingPersonaService.getCurrentPersonaId(member)).willReturn(PERSONA_ID);
        given(aiCharacterService.get(member)).willReturn(
            new AiCharacterResponse(CHARACTER_NAME, CharacterType.CHARACTER_1, List.of("a", "b", "c")));
        lenient().when(member.getId()).thenReturn(memberId);
        lenient().when(member.getNickname()).thenReturn(NICKNAME);
    }

    @Test
    void start_success_runsStepsInOrderAndReturnsResponse() {
        Map<String, Object> connection = Map.of("room", "room-1");
        AiCallSession session = new AiCallSession("call-session-1", "v1", "model-1", connection);
        stubStartable();
        given(callHistoryService.startPending(member, PERSONA_ID, LimitKind.PER_DAY)).willReturn(callHistoryId);
        given(aiCallSessionPort.createSession(sessionRequest)).willReturn(session);

        CallStartResponse response = callService.start(member);

        assertThat(response).isEqualTo(new CallStartResponse("call-session-1", 900L, connection));
        InOrder inOrder = inOrder(callLimitService, onboardingPersonaService, aiCharacterService,
            callHistoryService, aiCallSessionPort);
        inOrder.verify(callLimitService).checkStartable(member);
        inOrder.verify(onboardingPersonaService).getCurrentPersonaId(member);
        inOrder.verify(aiCharacterService).get(member);
        inOrder.verify(callHistoryService).startPending(member, PERSONA_ID, LimitKind.PER_DAY);
        inOrder.verify(aiCallSessionPort).createSession(sessionRequest);
        inOrder.verify(callHistoryService).activate(callHistoryId, session);
        verify(callHistoryService, never()).fail(any());
    }

    @Test
    void start_limitInsufficient_doesNotInsertOrCallAiServer() {
        given(callLimitService.checkStartable(member))
            .willThrow(new CustomException(ErrorCode.CALL_LIMIT_INSUFFICIENT));

        assertThatThrownBy(() -> callService.start(member))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.CALL_LIMIT_INSUFFICIENT));

        verifyNoInteractions(callHistoryService, aiCallSessionPort);
    }

    @Test
    void start_noOnboardingSubmission_doesNotInsertOrCallAiServer() {
        given(callLimitService.checkStartable(member)).willReturn(new CallLimitDecision(900L, LimitKind.PER_DAY));
        given(onboardingPersonaService.getCurrentPersonaId(member))
            .willThrow(new CustomException(ErrorCode.AI_CHARACTER_NOT_FOUND));

        assertThatThrownBy(() -> callService.start(member))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.AI_CHARACTER_NOT_FOUND));

        verifyNoInteractions(callHistoryService, aiCallSessionPort);
    }

    @Test
    void start_aiCharacterNotFound_doesNotInsertOrCallAiServer() {
        given(callLimitService.checkStartable(member)).willReturn(new CallLimitDecision(900L, LimitKind.PER_DAY));
        given(onboardingPersonaService.getCurrentPersonaId(member)).willReturn(PERSONA_ID);
        given(aiCharacterService.get(member)).willThrow(new CustomException(ErrorCode.AI_CHARACTER_NOT_FOUND));

        assertThatThrownBy(() -> callService.start(member))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.AI_CHARACTER_NOT_FOUND));

        verifyNoInteractions(callHistoryService, aiCallSessionPort);
    }

    @Test
    void start_alreadyInProgress_doesNotCallAiServer() {
        stubStartable();
        given(callHistoryService.startPending(member, PERSONA_ID, LimitKind.PER_DAY))
            .willThrow(new CustomException(ErrorCode.CALL_ALREADY_IN_PROGRESS));

        assertThatThrownBy(() -> callService.start(member))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.CALL_ALREADY_IN_PROGRESS));

        verifyNoInteractions(aiCallSessionPort);
    }

    @Test
    void start_aiServerUnavailable_failsPendingRecordAndRethrows() {
        stubStartable();
        given(callHistoryService.startPending(member, PERSONA_ID, LimitKind.PER_DAY)).willReturn(callHistoryId);
        given(aiCallSessionPort.createSession(sessionRequest))
            .willThrow(new CustomException(ErrorCode.AI_SERVER_UNAVAILABLE));

        assertThatThrownBy(() -> callService.start(member))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.AI_SERVER_UNAVAILABLE));

        verify(callHistoryService).fail(callHistoryId);
        verify(callHistoryService, never()).activate(any(), any());
    }

    @Test
    void start_activateFails_failsPendingRecordAndRethrows() {
        RuntimeException activateFailure = new IllegalStateException("db down");
        AiCallSession session = new AiCallSession("call-session-1", null, null, Map.of());
        stubStartable();
        given(callHistoryService.startPending(member, PERSONA_ID, LimitKind.PER_DAY)).willReturn(callHistoryId);
        given(aiCallSessionPort.createSession(sessionRequest)).willReturn(session);
        willThrow(activateFailure).given(callHistoryService).activate(callHistoryId, session);

        assertThatThrownBy(() -> callService.start(member)).isSameAs(activateFailure);

        verify(callHistoryService).fail(callHistoryId);
    }

    @Test
    void start_failItselfFails_originalExceptionIsKept() {
        CustomException original = new CustomException(ErrorCode.AI_SERVER_UNAVAILABLE);
        stubStartable();
        given(callHistoryService.startPending(member, PERSONA_ID, LimitKind.PER_DAY)).willReturn(callHistoryId);
        given(aiCallSessionPort.createSession(sessionRequest)).willThrow(original);
        willThrow(new IllegalStateException("fail failed")).given(callHistoryService).fail(callHistoryId);

        assertThatThrownBy(() -> callService.start(member)).isSameAs(original);
    }

}
