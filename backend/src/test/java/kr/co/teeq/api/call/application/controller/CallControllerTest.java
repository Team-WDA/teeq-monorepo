package kr.co.teeq.api.call.application.controller;

import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.call.application.dto.response.CallHistoryResponse;
import kr.co.teeq.api.call.application.service.CallService;
import kr.co.teeq.api.call.application.service.CallHistoryService;
import kr.co.teeq.api.call.core.constant.CallStatus;
import kr.co.teeq.api.common.application.exception.GlobalExceptionHandler;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.principal.AuthenticatedMember;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.method.annotation.AuthenticationPrincipalArgumentResolver;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

/**
 * 통화 취소 엔드포인트의 웹 계층(경로, 인증 principal 전달, 에러 응답)을 확인한다. 보안 필터는 포함하지 않는다.
 */
class CallControllerTest {

    private static final String CANCEL_PATH = "/api/calls/call-session-1/cancel";

    private final Member member = mock(Member.class);
    private final CallService callService = mock(CallService.class);
    private final CallHistoryService callHistoryService = mock(CallHistoryService.class);
    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        SecurityContextHolder.getContext().setAuthentication(
            new UsernamePasswordAuthenticationToken(new AuthenticatedMember(member), null, List.of()));
        mockMvc = MockMvcBuilders.standaloneSetup(new CallController(callService, callHistoryService))
            .setCustomArgumentResolvers(new AuthenticationPrincipalArgumentResolver())
            .setControllerAdvice(new GlobalExceptionHandler())
            .build();
    }

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void cancel_returns200WithCallHistoryAndPassesPrincipalMember() throws Exception {
        given(callHistoryService.cancel(member, "call-session-1")).willReturn(new CallHistoryResponse(
            "call-session-1", UUID.randomUUID(), Instant.parse("2026-11-14T00:00:00Z"), 0, CallStatus.CANCELLED));

        mockMvc.perform(post(CANCEL_PATH))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("CANCELLED"));

        verify(callHistoryService).cancel(member, "call-session-1");
    }

    @Test
    void cancel_unknownSession_returns404CallSessionNotFound() throws Exception {
        given(callHistoryService.cancel(member, "call-session-1"))
            .willThrow(new CustomException(ErrorCode.CALL_SESSION_NOT_FOUND));

        mockMvc.perform(post(CANCEL_PATH))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.errorCode").value("CALL_SESSION_NOT_FOUND"));
    }

}
