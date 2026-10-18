package kr.co.teeq.api.call.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.willThrow;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

import java.util.Map;
import java.util.UUID;
import kr.co.teeq.api.call.application.dto.response.CallStartResponse;
import kr.co.teeq.api.call.core.port.AiCallSession;
import kr.co.teeq.api.call.core.port.AiCallSessionPort;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InOrder;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class CallServiceTest {

    private final UUID memberId = UUID.randomUUID();
    private final UUID callHistoryId = UUID.randomUUID();

    @Mock
    private CallLimitService callLimitService;

    @Mock
    private CallHistoryService callHistoryService;

    @Mock
    private AiCallSessionPort aiCallSessionPort;

    @InjectMocks
    private CallService callService;

    @Test
    void start_success_runsStepsInOrderAndReturnsResponse() {
        Map<String, Object> connection = Map.of("room", "room-1");
        given(callLimitService.checkStartable(memberId)).willReturn(900L);
        given(callHistoryService.startPending(memberId)).willReturn(callHistoryId);
        given(aiCallSessionPort.createSession(memberId, 900L))
            .willReturn(new AiCallSession("call-session-1", connection));

        CallStartResponse response = callService.start(memberId);

        assertThat(response).isEqualTo(new CallStartResponse("call-session-1", 900L, connection));
        InOrder inOrder = inOrder(callLimitService, callHistoryService, aiCallSessionPort);
        inOrder.verify(callLimitService).checkStartable(memberId);
        inOrder.verify(callHistoryService).startPending(memberId);
        inOrder.verify(aiCallSessionPort).createSession(memberId, 900L);
        inOrder.verify(callHistoryService).activate(callHistoryId, "call-session-1");
        verify(callHistoryService, never()).fail(any());
    }

    @Test
    void start_limitInsufficient_doesNotInsertOrCallAiServer() {
        given(callLimitService.checkStartable(memberId))
            .willThrow(new CustomException(ErrorCode.CALL_LIMIT_INSUFFICIENT));

        assertThatThrownBy(() -> callService.start(memberId))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.CALL_LIMIT_INSUFFICIENT));

        verifyNoInteractions(callHistoryService, aiCallSessionPort);
    }

    @Test
    void start_alreadyInProgress_doesNotCallAiServer() {
        given(callLimitService.checkStartable(memberId)).willReturn(900L);
        given(callHistoryService.startPending(memberId))
            .willThrow(new CustomException(ErrorCode.CALL_ALREADY_IN_PROGRESS));

        assertThatThrownBy(() -> callService.start(memberId))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.CALL_ALREADY_IN_PROGRESS));

        verifyNoInteractions(aiCallSessionPort);
    }

    @Test
    void start_aiServerUnavailable_failsPendingRecordAndRethrows() {
        given(callLimitService.checkStartable(memberId)).willReturn(900L);
        given(callHistoryService.startPending(memberId)).willReturn(callHistoryId);
        given(aiCallSessionPort.createSession(memberId, 900L))
            .willThrow(new CustomException(ErrorCode.AI_SERVER_UNAVAILABLE));

        assertThatThrownBy(() -> callService.start(memberId))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.AI_SERVER_UNAVAILABLE));

        verify(callHistoryService).fail(callHistoryId);
        verify(callHistoryService, never()).activate(any(), anyString());
    }

    @Test
    void start_activateFails_failsPendingRecordAndRethrows() {
        RuntimeException activateFailure = new IllegalStateException("db down");
        given(callLimitService.checkStartable(memberId)).willReturn(900L);
        given(callHistoryService.startPending(memberId)).willReturn(callHistoryId);
        given(aiCallSessionPort.createSession(memberId, 900L))
            .willReturn(new AiCallSession("call-session-1", Map.of()));
        willThrow(activateFailure).given(callHistoryService).activate(callHistoryId, "call-session-1");

        assertThatThrownBy(() -> callService.start(memberId)).isSameAs(activateFailure);

        verify(callHistoryService).fail(callHistoryId);
    }

    @Test
    void start_failItselfFails_originalExceptionIsKept() {
        CustomException original = new CustomException(ErrorCode.AI_SERVER_UNAVAILABLE);
        given(callLimitService.checkStartable(memberId)).willReturn(900L);
        given(callHistoryService.startPending(memberId)).willReturn(callHistoryId);
        given(aiCallSessionPort.createSession(memberId, 900L)).willThrow(original);
        willThrow(new IllegalStateException("fail failed")).given(callHistoryService).fail(callHistoryId);

        assertThatThrownBy(() -> callService.start(memberId)).isSameAs(original);
    }

}
