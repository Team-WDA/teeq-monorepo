package kr.co.teeq.api.call.application.controller;

import static kr.co.teeq.api.admin.support.AdminTestAuthentication.asAdmin;
import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.LocalDate;
import java.util.List;
import kr.co.teeq.api.call.application.dto.response.CallUsageResponse;
import kr.co.teeq.api.call.application.service.CallUsageService;
import kr.co.teeq.api.call.core.constant.CallUsageUnit;
import kr.co.teeq.api.admin.infrastructure.config.AdminSecurityConfig;
import kr.co.teeq.api.admin.support.AdminSliceTestConfig;
import kr.co.teeq.api.common.application.exception.GlobalExceptionHandler;
import kr.co.teeq.api.member.core.repository.AdminRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.ImportAutoConfiguration;
import org.springframework.boot.autoconfigure.aop.AopAutoConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(controllers = CallUsageAdminController.class)
// 컨트롤러가 Docs 인터페이스를 구현하므로 클래스 기반 프록시(AopAutoConfiguration)가 있어야 매핑이 잡힌다
@ImportAutoConfiguration(AopAutoConfiguration.class)
@Import({
    AdminSecurityConfig.class,
    AdminSliceTestConfig.class,
    GlobalExceptionHandler.class,
    CallUsageAdminController.class
})
class CallUsageAdminControllerSecurityTest {

    private static final String PATH = "/api/admin/call-usages";
    private static final String VALID_QUERY = "?unit=DAY&from=2026-10-01&to=2026-10-02";

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AdminRepository adminRepository;

    @MockitoBean
    private CallUsageService callUsageService;

    @Test
    void noSession_returns401Json() throws Exception {
        mockMvc.perform(get(PATH + VALID_QUERY))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.errorCode").value("UNAUTHENTICATED"));
    }

    @Test
    void adminSession_returns200() throws Exception {
        given(callUsageService.getUsages(CallUsageUnit.DAY, LocalDate.of(2026, 10, 1), LocalDate.of(2026, 10, 2),
            null)).willReturn(List.of(new CallUsageResponse(LocalDate.of(2026, 10, 1), 600, 2)));

        mockMvc.perform(get(PATH + VALID_QUERY).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$[0].periodStart").value("2026-10-01"))
            .andExpect(jsonPath("$[0].usedSeconds").value(600))
            .andExpect(jsonPath("$[0].callCount").value(2));
    }

    @Test
    void adminSession_withInvalidUnit_returns400() throws Exception {
        mockMvc.perform(get(PATH + "?unit=WEEK&from=2026-10-01&to=2026-10-02")
                .with(asAdmin()))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errorCode").value("INVALID_REQUEST"));
    }

    @Test
    void adminSession_withMalformedDate_returns400() throws Exception {
        mockMvc.perform(get(PATH + "?unit=DAY&from=20261001&to=2026-10-02")
                .with(asAdmin()))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errorCode").value("INVALID_REQUEST"));
    }

    @Test
    void adminSession_withoutRequiredParameter_returns400() throws Exception {
        mockMvc.perform(get(PATH + "?unit=DAY&from=2026-10-01")
                .with(asAdmin()))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errorCode").value("INVALID_REQUEST"));
    }

}
