package kr.co.teeq.api.admin.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verifyNoInteractions;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.admin.application.dto.response.AdminCallDetailResponse;
import kr.co.teeq.api.admin.application.dto.response.AdminCallDetailResponse.ConversationState;
import kr.co.teeq.api.call.application.dto.response.CallHistoryItemResponse;
import kr.co.teeq.api.call.application.service.CallHistoryQueryService;
import kr.co.teeq.api.call.core.constant.CallStatus;
import kr.co.teeq.api.call.core.port.AiCallDetail;
import kr.co.teeq.api.call.core.port.AiCallDetailPort;
import kr.co.teeq.api.call.core.port.AiCallTurn;
import kr.co.teeq.api.call.core.port.AiCallTurnRole;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class AdminCallDetailServiceTest {

    private static final String SESSION_ID = "sess-1";

    @Mock
    private CallHistoryQueryService callHistoryQueryService;
    @Mock
    private AiCallDetailPort aiCallDetailPort;
    @InjectMocks
    private AdminCallDetailService service;

    @Test
    void 대화가_있으면_LOADED이고_AI_상세를_담는다() {
        CallHistoryItemResponse call = call();
        AiCallDetail detail = detail(List.of(new AiCallTurn(0, AiCallTurnRole.USER, "안녕", false, null, null)));
        given(callHistoryQueryService.getBySessionId(SESSION_ID)).willReturn(call);
        given(aiCallDetailPort.find(SESSION_ID)).willReturn(Optional.of(detail));

        AdminCallDetailResponse response = service.getDetail(SESSION_ID);

        assertThat(response.call()).isSameAs(call);
        assertThat(response.conversationState()).isEqualTo(ConversationState.LOADED);
        assertThat(response.aiDetail()).isSameAs(detail);
    }

    @Test
    void turns가_비어_있으면_EXPIRED이고_AI_상세도_담는다() {
        AiCallDetail detail = detail(List.of());
        given(callHistoryQueryService.getBySessionId(SESSION_ID)).willReturn(call());
        given(aiCallDetailPort.find(SESSION_ID)).willReturn(Optional.of(detail));

        AdminCallDetailResponse response = service.getDetail(SESSION_ID);

        assertThat(response.conversationState()).isEqualTo(ConversationState.EXPIRED);
        assertThat(response.aiDetail()).isSameAs(detail);
    }

    @Test
    void AI_서버에_세션이_없으면_NOT_RECORDED이고_AI_상세는_없다() {
        given(callHistoryQueryService.getBySessionId(SESSION_ID)).willReturn(call());
        given(aiCallDetailPort.find(SESSION_ID)).willReturn(Optional.empty());

        AdminCallDetailResponse response = service.getDetail(SESSION_ID);

        assertThat(response.conversationState()).isEqualTo(ConversationState.NOT_RECORDED);
        assertThat(response.aiDetail()).isNull();
    }

    @Test
    void AI_서버를_쓸_수_없으면_UNAVAILABLE이고_통화_정보는_유지한다() {
        CallHistoryItemResponse call = call();
        given(callHistoryQueryService.getBySessionId(SESSION_ID)).willReturn(call);
        given(aiCallDetailPort.find(SESSION_ID)).willThrow(new CustomException(ErrorCode.AI_SERVER_UNAVAILABLE));

        AdminCallDetailResponse response = service.getDetail(SESSION_ID);

        assertThat(response.call()).isSameAs(call);
        assertThat(response.conversationState()).isEqualTo(ConversationState.UNAVAILABLE);
        assertThat(response.aiDetail()).isNull();
    }

    @Test
    void 다른_ErrorCode의_예외는_그대로_전파한다() {
        given(callHistoryQueryService.getBySessionId(SESSION_ID)).willReturn(call());
        given(aiCallDetailPort.find(SESSION_ID)).willThrow(new CustomException(ErrorCode.INVALID_REQUEST));

        assertThatThrownBy(() -> service.getDetail(SESSION_ID))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.INVALID_REQUEST));
    }

    @Test
    void BE에_통화가_없으면_AI_서버를_호출하지_않고_예외를_전파한다() {
        given(callHistoryQueryService.getBySessionId(SESSION_ID))
            .willThrow(new CustomException(ErrorCode.CALL_SESSION_NOT_FOUND));

        assertThatThrownBy(() -> service.getDetail(SESSION_ID))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.CALL_SESSION_NOT_FOUND));
        verifyNoInteractions(aiCallDetailPort);
    }

    private CallHistoryItemResponse call() {
        return new CallHistoryItemResponse(SESSION_ID, UUID.randomUUID(), "소연", "a@b.c",
            Instant.parse("2026-11-09T01:00:00Z"), 60, CallStatus.ENDED, null, null);
    }

    private AiCallDetail detail(List<AiCallTurn> turns) {
        return new AiCallDetail(SESSION_ID, null, null, null, null, turns);
    }

}
