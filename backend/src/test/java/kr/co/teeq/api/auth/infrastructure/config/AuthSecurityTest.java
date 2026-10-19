package kr.co.teeq.api.auth.infrastructure.config;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.auth.infrastructure.properties.JwtProperties;
import kr.co.teeq.api.common.application.exception.GlobalExceptionHandler;
import kr.co.teeq.api.member.core.constant.Role;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.principal.AuthenticatedAdmin;
import kr.co.teeq.api.member.core.principal.AuthenticatedMember;
import kr.co.teeq.api.member.core.repository.MemberRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.context.HttpSessionSecurityContextRepository;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@WebMvcTest(controllers = AuthSecurityTest.ProbeController.class)
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
    AuthSecurityTest.ProbeController.class,
    AuthSecurityTest.FixedClockConfig.class
})
class AuthSecurityTest {

    private static final Instant NOW = Instant.parse("2026-10-16T00:00:00Z");
    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JwtProvider jwtProvider;

    @Autowired
    private JwtProperties jwtProperties;

    @MockitoBean
    private MemberRepository memberRepository;

    private Member member(Role role) {
        Member member = Member.builder()
            .email("soyeon@teeq.com")
            .password("encoded")
            .nickname("소연")
            .serviceTermsAgreed(true)
            .privacyPolicyAgreed(true)
            .build();
        ReflectionTestUtils.setField(member, "id", MEMBER_ID);
        ReflectionTestUtils.setField(member, "role", role);
        return member;
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }

    @Test
    void noToken_returns401Unauthenticated() throws Exception {
        mockMvc.perform(get("/probe/authenticated"))
            .andExpect(status().isUnauthorized())
            .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
            .andExpect(jsonPath("$.errorCode").value("UNAUTHENTICATED"));
    }

    @Test
    void garbageToken_returns401Unauthenticated() throws Exception {
        mockMvc.perform(get("/probe/authenticated").header(HttpHeaders.AUTHORIZATION, bearer("not-a-jwt")))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.errorCode").value("UNAUTHENTICATED"));
    }

    @Test
    void expiredToken_returns401ExpiredToken() throws Exception {
        JwtProvider pastProvider = new JwtProvider(jwtProperties, Clock.fixed(NOW.minus(Duration.ofDays(2)), ZoneOffset.UTC));
        String expired = pastProvider.issueAccessToken(MEMBER_ID);

        mockMvc.perform(get("/probe/authenticated").header(HttpHeaders.AUTHORIZATION, bearer(expired)))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.errorCode").value("EXPIRED_TOKEN"));
    }

    @Test
    void refreshTokenAsBearer_returns401Unauthenticated() throws Exception {
        String refreshToken = jwtProvider.issueRefreshToken(MEMBER_ID).token();

        mockMvc.perform(get("/probe/authenticated").header(HttpHeaders.AUTHORIZATION, bearer(refreshToken)))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.errorCode").value("UNAUTHENTICATED"));
    }

    @Test
    void validTokenOfDeletedMember_returns401Unauthenticated() throws Exception {
        given(memberRepository.findByIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.empty());
        String token = jwtProvider.issueAccessToken(MEMBER_ID);

        mockMvc.perform(get("/probe/authenticated").header(HttpHeaders.AUTHORIZATION, bearer(token)))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.errorCode").value("UNAUTHENTICATED"));
    }

    @Test
    void validToken_exposesMemberAsPrincipal() throws Exception {
        given(memberRepository.findByIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.of(member(Role.USER)));
        String token = jwtProvider.issueAccessToken(MEMBER_ID);

        mockMvc.perform(get("/probe/authenticated").header(HttpHeaders.AUTHORIZATION, bearer(token)))
            .andExpect(status().isOk())
            .andExpect(content().string("소연"));
    }

    @Test
    void adminSession_isRejectedOnJwtApiPath() throws Exception {
        // JWT 체인은 STATELESS라 세션에 담긴 관리자 인증을 읽지 않는다
        SecurityContext securityContext = SecurityContextHolder.createEmptyContext();
        securityContext.setAuthentication(UsernamePasswordAuthenticationToken.authenticated(
            new AuthenticatedAdmin(UUID.randomUUID(), "operator", "운영자"), null,
            List.of(new SimpleGrantedAuthority("ROLE_ADMIN"))));
        MockHttpSession session = new MockHttpSession();
        session.setAttribute(HttpSessionSecurityContextRepository.SPRING_SECURITY_CONTEXT_KEY, securityContext);

        mockMvc.perform(get("/probe/authenticated").session(session))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.errorCode").value("UNAUTHENTICATED"));
    }

    @Test
    void publicPaths_areNotBlockedByAuthentication() throws Exception {
        for (var request : new org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder[] {
            post("/api/members"),
            post("/api/auth/login"),
            post("/api/auth/refresh"),
            post("/api/auth/social-login"),
            post("/api/auth/apple/callback"),
            get("/api/members/nickname-availability")
        }) {
            int httpStatus = mockMvc.perform(request).andReturn().getResponse().getStatus();
            assertThat(httpStatus).isNotIn(401, 403);
        }
    }

    @Test
    void nonPostMethodsOnMembersPath_areStillProtected() throws Exception {
        mockMvc.perform(get("/api/members"))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.errorCode").value("UNAUTHENTICATED"));
        mockMvc.perform(delete("/api/members"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void invalidTokenOnPublicPath_isNotRejectedByFilter() throws Exception {
        int httpStatus = mockMvc.perform(post("/api/auth/login").header(HttpHeaders.AUTHORIZATION, bearer("not-a-jwt")))
            .andReturn().getResponse().getStatus();

        assertThat(httpStatus).isNotIn(401, 403);
    }

    @RestController
    static class ProbeController {

        @GetMapping("/probe/authenticated")
        String authenticated(@AuthenticationPrincipal AuthenticatedMember authenticatedMember) {
            return authenticatedMember.member().getNickname();
        }

    }

    @TestConfiguration(proxyBeanMethods = false)
    static class FixedClockConfig {

        @Bean
        Clock clock() {
            return Clock.fixed(NOW, ZoneOffset.UTC);
        }

    }

}
