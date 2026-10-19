package kr.co.teeq.api.call.application.controller;

import static kr.co.teeq.api.admin.support.AdminTestAuthentication.ADMIN_ID;
import static kr.co.teeq.api.admin.support.AdminTestAuthentication.asAdmin;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verify;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.admin.infrastructure.config.AdminSecurityConfig;
import kr.co.teeq.api.admin.support.AdminSliceTestConfig;
import kr.co.teeq.api.call.application.dto.request.CallBonusGrantRequest;
import kr.co.teeq.api.call.application.dto.response.CallBonusResponse;
import kr.co.teeq.api.call.application.service.CallBonusService;
import kr.co.teeq.api.common.application.exception.GlobalExceptionHandler;
import kr.co.teeq.api.member.core.repository.AdminRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.ImportAutoConfiguration;
import org.springframework.boot.autoconfigure.aop.AopAutoConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(controllers = CallBonusAdminController.class)
// 컨트롤러가 Docs 인터페이스를 구현하므로 클래스 기반 프록시(AopAutoConfiguration)가 있어야 매핑이 잡힌다
@ImportAutoConfiguration(AopAutoConfiguration.class)
@Import({
    AdminSecurityConfig.class,
    AdminSliceTestConfig.class,
    GlobalExceptionHandler.class,
    CallBonusAdminController.class
})
class CallBonusAdminControllerSecurityTest {

    private static final Instant NOW = Instant.parse("2026-10-16T00:00:00Z");
    private static final UUID TARGET_MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5c");
    private static final String BASE_PATH = "/api/admin/members/" + TARGET_MEMBER_ID + "/call-bonuses";
    private static final String VALID_BODY = "{\"seconds\":600,\"reason\":\"장애 보상\"}";

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AdminRepository adminRepository;

    @MockitoBean
    private CallBonusService callBonusService;

    @Test
    void noSession_returns401Json() throws Exception {
        mockMvc.perform(get(BASE_PATH))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.errorCode").value("UNAUTHENTICATED"));
    }

    @Test
    void adminSession_grant_returns201() throws Exception {
        given(callBonusService.grant(any(), any(), any())).willReturn(new CallBonusResponse(
            UUID.randomUUID(), TARGET_MEMBER_ID, LocalDate.of(2026, 10, 16), 600, "장애 보상", ADMIN_ID,
            false, null, null, NOW));

        mockMvc.perform(post(BASE_PATH)
                .with(asAdmin()).with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(VALID_BODY))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.seconds").value(600))
            .andExpect(jsonPath("$.canceled").value(false));

        verify(callBonusService).grant(eq(ADMIN_ID), eq(TARGET_MEMBER_ID), any(CallBonusGrantRequest.class));
    }

    @Test
    void grantWithoutCsrf_returns403() throws Exception {
        mockMvc.perform(post(BASE_PATH)
                .with(asAdmin())
                .contentType(MediaType.APPLICATION_JSON)
                .content(VALID_BODY))
            .andExpect(status().isForbidden())
            .andExpect(jsonPath("$.errorCode").value("ACCESS_DENIED"));
    }

    private void assertGrantReturnsInvalidRequest(String body) throws Exception {
        mockMvc.perform(post(BASE_PATH)
                .with(asAdmin()).with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(body))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errorCode").value("INVALID_REQUEST"));
    }

    @Test
    void adminSession_grantWithSecondsOverMax_returns400() throws Exception {
        assertGrantReturnsInvalidRequest("{\"seconds\":3601,\"reason\":\"장애 보상\"}");
    }

    @Test
    void adminSession_grantWithoutSeconds_returns400() throws Exception {
        assertGrantReturnsInvalidRequest("{\"reason\":\"장애 보상\"}");
    }

    @Test
    void adminSession_grantWithBlankReason_returns400() throws Exception {
        assertGrantReturnsInvalidRequest("{\"seconds\":600,\"reason\":\"\"}");
    }

    @Test
    void adminSession_grantWithTooLongReason_returns400() throws Exception {
        assertGrantReturnsInvalidRequest("{\"seconds\":600,\"reason\":\"" + "가".repeat(201) + "\"}");
    }

    @Test
    void adminSession_getList_returns200() throws Exception {
        given(callBonusService.getAll(TARGET_MEMBER_ID)).willReturn(List.of());

        mockMvc.perform(get(BASE_PATH).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$").isEmpty());
    }

    @Test
    void adminSession_cancel_returns204() throws Exception {
        UUID callBonusId = UUID.randomUUID();

        mockMvc.perform(delete(BASE_PATH + "/" + callBonusId).with(asAdmin()).with(csrf()))
            .andExpect(status().isNoContent());

        verify(callBonusService).cancel(ADMIN_ID, TARGET_MEMBER_ID, callBonusId);
    }

}
