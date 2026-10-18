package kr.co.teeq.api.call.application.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.auth.infrastructure.config.JwtAccessDeniedHandler;
import kr.co.teeq.api.auth.infrastructure.config.JwtAuthenticationEntryPoint;
import kr.co.teeq.api.auth.infrastructure.config.JwtProvider;
import kr.co.teeq.api.auth.infrastructure.config.SecurityConfig;
import kr.co.teeq.api.call.application.dto.response.CallBonusResponse;
import kr.co.teeq.api.call.application.service.CallBonusService;
import kr.co.teeq.api.common.application.exception.GlobalExceptionHandler;
import kr.co.teeq.api.member.core.constant.Role;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.repository.MemberRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.ImportAutoConfiguration;
import org.springframework.boot.autoconfigure.aop.AopAutoConfiguration;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(controllers = CallBonusAdminController.class)
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
    CallBonusAdminController.class,
    CallBonusAdminControllerSecurityTest.FixedClockConfig.class
})
class CallBonusAdminControllerSecurityTest {

    private static final Instant NOW = Instant.parse("2026-10-16T00:00:00Z");
    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final UUID TARGET_MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5c");
    private static final String BASE_PATH = "/api/admin/members/" + TARGET_MEMBER_ID + "/call-bonuses";
    private static final String VALID_BODY = "{\"seconds\":600,\"reason\":\"장애 보상\"}";

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JwtProvider jwtProvider;

    @MockitoBean
    private MemberRepository memberRepository;

    @MockitoBean
    private CallBonusService callBonusService;

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
        mockMvc.perform(get(BASE_PATH))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.errorCode").value("UNAUTHENTICATED"));
    }

    @Test
    void userRole_grant_returns403() throws Exception {
        mockMvc.perform(post(BASE_PATH)
                .header(HttpHeaders.AUTHORIZATION, bearerFor(Role.USER))
                .contentType(MediaType.APPLICATION_JSON)
                .content(VALID_BODY))
            .andExpect(status().isForbidden())
            .andExpect(jsonPath("$.errorCode").value("ACCESS_DENIED"));
    }

    @Test
    void adminRole_grant_returns201() throws Exception {
        given(callBonusService.grant(any(), any(), any())).willReturn(new CallBonusResponse(
            UUID.randomUUID(), TARGET_MEMBER_ID, LocalDate.of(2026, 10, 16), 600, "장애 보상", MEMBER_ID,
            false, null, null, NOW));

        mockMvc.perform(post(BASE_PATH)
                .header(HttpHeaders.AUTHORIZATION, bearerFor(Role.ADMIN))
                .contentType(MediaType.APPLICATION_JSON)
                .content(VALID_BODY))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.seconds").value(600))
            .andExpect(jsonPath("$.canceled").value(false));
    }

    private void assertGrantReturnsInvalidRequest(String body) throws Exception {
        mockMvc.perform(post(BASE_PATH)
                .header(HttpHeaders.AUTHORIZATION, bearerFor(Role.ADMIN))
                .contentType(MediaType.APPLICATION_JSON)
                .content(body))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errorCode").value("INVALID_REQUEST"));
    }

    @Test
    void adminRole_grantWithSecondsOverMax_returns400() throws Exception {
        assertGrantReturnsInvalidRequest("{\"seconds\":3601,\"reason\":\"장애 보상\"}");
    }

    @Test
    void adminRole_grantWithoutSeconds_returns400() throws Exception {
        assertGrantReturnsInvalidRequest("{\"reason\":\"장애 보상\"}");
    }

    @Test
    void adminRole_grantWithBlankReason_returns400() throws Exception {
        assertGrantReturnsInvalidRequest("{\"seconds\":600,\"reason\":\"\"}");
    }

    @Test
    void adminRole_grantWithTooLongReason_returns400() throws Exception {
        assertGrantReturnsInvalidRequest("{\"seconds\":600,\"reason\":\"" + "가".repeat(201) + "\"}");
    }

    @Test
    void userRole_getList_returns403() throws Exception {
        mockMvc.perform(get(BASE_PATH).header(HttpHeaders.AUTHORIZATION, bearerFor(Role.USER)))
            .andExpect(status().isForbidden())
            .andExpect(jsonPath("$.errorCode").value("ACCESS_DENIED"));
    }

    @Test
    void userRole_cancel_returns403() throws Exception {
        mockMvc.perform(delete(BASE_PATH + "/" + UUID.randomUUID())
                .header(HttpHeaders.AUTHORIZATION, bearerFor(Role.USER)))
            .andExpect(status().isForbidden())
            .andExpect(jsonPath("$.errorCode").value("ACCESS_DENIED"));
    }

    @Test
    void adminRole_getList_returns200() throws Exception {
        given(callBonusService.getAll(TARGET_MEMBER_ID)).willReturn(List.of());

        mockMvc.perform(get(BASE_PATH).header(HttpHeaders.AUTHORIZATION, bearerFor(Role.ADMIN)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$").isEmpty());
    }

    @Test
    void adminRole_cancel_returns204() throws Exception {
        mockMvc.perform(delete(BASE_PATH + "/" + UUID.randomUUID())
                .header(HttpHeaders.AUTHORIZATION, bearerFor(Role.ADMIN)))
            .andExpect(status().isNoContent());
    }

    @TestConfiguration(proxyBeanMethods = false)
    static class FixedClockConfig {

        @Bean
        Clock clock() {
            return Clock.fixed(NOW, ZoneOffset.UTC);
        }

    }

}
