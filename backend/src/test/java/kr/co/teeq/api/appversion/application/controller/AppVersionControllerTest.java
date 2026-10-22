package kr.co.teeq.api.appversion.application.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import kr.co.teeq.api.appversion.application.dto.response.AppVersionCheckResponse;
import kr.co.teeq.api.appversion.application.service.AppVersionService;
import kr.co.teeq.api.appversion.core.constant.AppPlatform;
import kr.co.teeq.api.auth.infrastructure.config.JwtAccessDeniedHandler;
import kr.co.teeq.api.auth.infrastructure.config.JwtAuthenticationEntryPoint;
import kr.co.teeq.api.auth.infrastructure.config.JwtProvider;
import kr.co.teeq.api.auth.infrastructure.config.SecurityConfig;
import kr.co.teeq.api.common.application.exception.GlobalExceptionHandler;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.repository.MemberRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.ImportAutoConfiguration;
import org.springframework.boot.autoconfigure.aop.AopAutoConfiguration;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(controllers = AppVersionController.class)
// 컨트롤러가 Docs 인터페이스를 구현하므로 클래스 기반 프록시(AopAutoConfiguration)가 있어야 매핑이 잡힌다
@ImportAutoConfiguration(AopAutoConfiguration.class)
@ActiveProfiles("test")
@TestPropertySource(properties = {
    "jwt.secret-key=security-slice-dummy-secret-key-0123456789-abcdefghijklmnopqrstuvwxyz-ABCDEFG",
    "jwt.access-exp-millis=3600000",
    "jwt.refresh-exp-millis=7200000",
    "jwt.issuer=test-issuer"
})
@Import({
    SecurityConfig.class,
    JwtProvider.class,
    JwtAuthenticationEntryPoint.class,
    JwtAccessDeniedHandler.class,
    GlobalExceptionHandler.class,
    AppVersionController.class,
    AppVersionControllerTest.FixedClockConfig.class
})
class AppVersionControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private MemberRepository memberRepository;

    @MockitoBean
    private AppVersionService appVersionService;

    @Test
    void check_withoutAuthorization_returns200() throws Exception {
        given(appVersionService.check(AppPlatform.ANDROID, "1.2.3"))
            .willReturn(new AppVersionCheckResponse(true, "1.3.0", "https://store.example.com"));

        mockMvc.perform(get("/api/app-versions/check").param("platform", "ANDROID").param("appVersion", "1.2.3"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.updateRequired").value(true))
            .andExpect(jsonPath("$.minimumVersion").value("1.3.0"))
            .andExpect(jsonPath("$.storeUrl").value("https://store.example.com"));
    }

    @Test
    void check_lowercasePlatform_returns400() throws Exception {
        mockMvc.perform(get("/api/app-versions/check").param("platform", "android").param("appVersion", "1.2.3"))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errorCode").value("INVALID_REQUEST"));
    }

    @Test
    void check_missingPlatform_returns400() throws Exception {
        mockMvc.perform(get("/api/app-versions/check").param("appVersion", "1.2.3"))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errorCode").value("INVALID_REQUEST"));
    }

    @Test
    void check_missingAppVersion_returns400() throws Exception {
        mockMvc.perform(get("/api/app-versions/check").param("platform", "IOS"))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errorCode").value("INVALID_REQUEST"));
    }

    @Test
    void check_serviceRejectsVersion_returns400() throws Exception {
        given(appVersionService.check(any(), any())).willThrow(new CustomException(ErrorCode.INVALID_REQUEST));

        mockMvc.perform(get("/api/app-versions/check").param("platform", "IOS").param("appVersion", "abc"))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errorCode").value("INVALID_REQUEST"));
    }

    @TestConfiguration
    static class FixedClockConfig {

        @Bean
        Clock clock() {
            return Clock.fixed(Instant.parse("2026-10-16T00:00:00Z"), ZoneOffset.UTC);
        }

    }

}
