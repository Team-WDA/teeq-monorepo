package kr.teeq.api.call.application.controller;

import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kr.teeq.api.auth.infrastructure.config.JwtAccessDeniedHandler;
import kr.teeq.api.auth.infrastructure.config.JwtAuthenticationEntryPoint;
import kr.teeq.api.auth.infrastructure.config.JwtProvider;
import kr.teeq.api.auth.infrastructure.config.SecurityConfig;
import kr.teeq.api.call.application.dto.response.CallUsageResponse;
import kr.teeq.api.call.application.service.CallUsageService;
import kr.teeq.api.call.core.constant.CallUsageUnit;
import kr.teeq.api.common.application.exception.GlobalExceptionHandler;
import kr.teeq.api.member.core.constant.Role;
import kr.teeq.api.member.core.entity.Member;
import kr.teeq.api.member.core.repository.MemberRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.ImportAutoConfiguration;
import org.springframework.boot.autoconfigure.aop.AopAutoConfiguration;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(controllers = CallUsageAdminController.class)
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
    CallUsageAdminController.class,
    CallUsageAdminControllerSecurityTest.FixedClockConfig.class
})
class CallUsageAdminControllerSecurityTest {

    private static final Instant NOW = Instant.parse("2026-10-16T00:00:00Z");
    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final String PATH = "/api/admin/call-usages";
    private static final String VALID_QUERY = "?unit=DAY&from=2026-10-01&to=2026-10-02";

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JwtProvider jwtProvider;

    @MockitoBean
    private MemberRepository memberRepository;

    @MockitoBean
    private CallUsageService callUsageService;

    private String bearerFor(Role role) {
        Member member = Member.builder()
            .email("soyeon@teeq.com")
            .password("encoded")
            .nickname("소연")
            .serviceTermsAgreed(true)
            .privacyPolicyAgreed(true)
            .build();
        ReflectionTestUtils.setField(member, "id", MEMBER_ID);
        ReflectionTestUtils.setField(member, "role", role);
        given(memberRepository.findByIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.of(member));
        return "Bearer " + jwtProvider.issueAccessToken(MEMBER_ID);
    }

    @Test
    void noToken_returns401() throws Exception {
        mockMvc.perform(get(PATH + VALID_QUERY))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.errorCode").value("UNAUTHENTICATED"));
    }

    @Test
    void userRole_returns403() throws Exception {
        mockMvc.perform(get(PATH + VALID_QUERY).header(HttpHeaders.AUTHORIZATION, bearerFor(Role.USER)))
            .andExpect(status().isForbidden())
            .andExpect(jsonPath("$.errorCode").value("ACCESS_DENIED"));
    }

    @Test
    void adminRole_returns200() throws Exception {
        given(callUsageService.getUsages(CallUsageUnit.DAY, LocalDate.of(2026, 10, 1), LocalDate.of(2026, 10, 2),
            null)).willReturn(List.of(new CallUsageResponse(LocalDate.of(2026, 10, 1), 600, 2)));

        mockMvc.perform(get(PATH + VALID_QUERY).header(HttpHeaders.AUTHORIZATION, bearerFor(Role.ADMIN)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$[0].periodStart").value("2026-10-01"))
            .andExpect(jsonPath("$[0].usedSeconds").value(600))
            .andExpect(jsonPath("$[0].callCount").value(2));
    }

    @Test
    void adminRole_withInvalidUnit_returns400() throws Exception {
        mockMvc.perform(get(PATH + "?unit=WEEK&from=2026-10-01&to=2026-10-02")
                .header(HttpHeaders.AUTHORIZATION, bearerFor(Role.ADMIN)))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errorCode").value("INVALID_REQUEST"));
    }

    @Test
    void adminRole_withMalformedDate_returns400() throws Exception {
        mockMvc.perform(get(PATH + "?unit=DAY&from=20261001&to=2026-10-02")
                .header(HttpHeaders.AUTHORIZATION, bearerFor(Role.ADMIN)))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errorCode").value("INVALID_REQUEST"));
    }

    @Test
    void adminRole_withoutRequiredParameter_returns400() throws Exception {
        mockMvc.perform(get(PATH + "?unit=DAY&from=2026-10-01")
                .header(HttpHeaders.AUTHORIZATION, bearerFor(Role.ADMIN)))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errorCode").value("INVALID_REQUEST"));
    }

    @TestConfiguration(proxyBeanMethods = false)
    static class FixedClockConfig {

        @Bean
        Clock clock() {
            return Clock.fixed(NOW, ZoneOffset.UTC);
        }

    }

}
