package kr.co.teeq.api.call.application.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.UUID;
import kr.co.teeq.api.auth.infrastructure.config.AiServerSecurityConfig;
import kr.co.teeq.api.auth.infrastructure.config.JwtAccessDeniedHandler;
import kr.co.teeq.api.auth.infrastructure.config.JwtAuthenticationEntryPoint;
import kr.co.teeq.api.auth.infrastructure.config.JwtProvider;
import kr.co.teeq.api.auth.infrastructure.config.SecurityConfig;
import kr.co.teeq.api.call.application.dto.request.CallUsageReportRequest;
import kr.co.teeq.api.call.application.dto.response.CallHistoryResponse;
import kr.co.teeq.api.call.application.service.CallHistoryService;
import kr.co.teeq.api.call.core.constant.CallStatus;
import kr.co.teeq.api.call.core.constant.EndReason;
import kr.co.teeq.api.common.application.exception.GlobalExceptionHandler;
import kr.co.teeq.api.common.infrastructure.config.AiServerPropertiesConfig;
import kr.co.teeq.api.member.core.repository.MemberRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

@WebMvcTest(controllers = AiServerCallController.class)
@ActiveProfiles("test")
@TestPropertySource(properties = {
    "ai-server.base-url=http://localhost:9999",
    "ai-server.auth-header-name=X-Teeq-Server-Key",
    "ai-server.auth-header-value=dummy-server-key-value",
    "jwt.secret-key=security-slice-dummy-secret-key-0123456789-abcdefghijklmnopqrstuvwxyz-ABCDEFG",
    "jwt.access-exp-millis=3600000",
    "jwt.refresh-exp-millis=7200000",
    "jwt.issuer=test-issuer"
})
@Import({
    AiServerPropertiesConfig.class,
    AiServerSecurityConfig.class,
    SecurityConfig.class,
    JwtProvider.class,
    JwtAuthenticationEntryPoint.class,
    JwtAccessDeniedHandler.class,
    GlobalExceptionHandler.class,
    AiServerCallControllerTest.FixedClockConfig.class
})
class AiServerCallControllerTest {

    private static final Instant NOW = Instant.parse("2026-10-16T00:00:00Z");
    private static final Instant ENDED_AT = Instant.parse("2026-10-16T03:05:00Z");
    private static final String USAGE_PATH = "/api/ai-server/calls/call-session-1/usage";
    private static final String SERVER_KEY_HEADER = "X-Teeq-Server-Key";
    private static final String SERVER_KEY_VALUE = "dummy-server-key-value";

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private CallHistoryService callHistoryService;

    @MockitoBean
    private MemberRepository memberRepository;

    private ResultActions reportUsage(String body) throws Exception {
        return mockMvc.perform(post(USAGE_PATH)
            .header(SERVER_KEY_HEADER, SERVER_KEY_VALUE)
            .contentType(MediaType.APPLICATION_JSON)
            .content(body));
    }

    @Test
    void unknownEndReason_returns400MalformedRequestBody() throws Exception {
        reportUsage("""
            {"usedSeconds": 300, "endedAt": "2026-10-16T03:05:00Z", "endReason": "FOO"}""")
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errorCode").value("MALFORMED_REQUEST_BODY"));

        verify(callHistoryService, never()).reportUsage(any(), any());
    }

    @Test
    void missingEndReason_returns400InvalidRequest() throws Exception {
        reportUsage("""
            {"usedSeconds": 300, "endedAt": "2026-10-16T03:05:00Z"}""")
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errorCode").value("INVALID_REQUEST"));

        verify(callHistoryService, never()).reportUsage(any(), any());
    }

    @Test
    void validEndReason_returns200AndPassesRequestToService() throws Exception {
        CallUsageReportRequest expected = new CallUsageReportRequest(300, ENDED_AT, EndReason.LIMIT_REACHED);
        given(callHistoryService.reportUsage("call-session-1", expected))
            .willReturn(new CallHistoryResponse("call-session-1", UUID.randomUUID(), NOW, 300, CallStatus.ENDED));

        reportUsage("""
            {"usedSeconds": 300, "endedAt": "2026-10-16T03:05:00Z", "endReason": "LIMIT_REACHED"}""")
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("ENDED"));

        verify(callHistoryService).reportUsage("call-session-1", expected);
    }

    @TestConfiguration(proxyBeanMethods = false)
    static class FixedClockConfig {

        @Bean
        Clock clock() {
            return Clock.fixed(NOW, ZoneOffset.UTC);
        }

    }

}
