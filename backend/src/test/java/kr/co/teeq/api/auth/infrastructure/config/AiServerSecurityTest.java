package kr.co.teeq.api.auth.infrastructure.config;

import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.common.application.exception.GlobalExceptionHandler;
import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.common.infrastructure.config.AiServerPropertiesConfig;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.repository.MemberRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@WebMvcTest(controllers = AiServerSecurityTest.ProbeController.class)
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
    AiServerSecurityTest.ProbeController.class,
    AiServerSecurityTest.FixedClockConfig.class
})
class AiServerSecurityTest {

    private static final Instant NOW = Instant.parse("2026-10-16T00:00:00Z");
    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final String SERVER_KEY_HEADER = "X-Teeq-Server-Key";
    private static final String SERVER_KEY_VALUE = "dummy-server-key-value";

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JwtProvider jwtProvider;

    @MockitoBean
    private MemberRepository memberRepository;

    @Test
    void correctServerHeader_allowsAiServerPath() throws Exception {
        mockMvc.perform(get("/api/ai-server/probe").header(SERVER_KEY_HEADER, SERVER_KEY_VALUE))
            .andExpect(status().isOk())
            .andExpect(content().string("ok"));
    }

    @Test
    void missingServerHeader_returns401Unauthenticated() throws Exception {
        mockMvc.perform(get("/api/ai-server/probe"))
            .andExpect(status().isUnauthorized())
            .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
            .andExpect(jsonPath("$.errorCode").value("UNAUTHENTICATED"));
    }

    @Test
    void wrongServerHeader_returns401Unauthenticated() throws Exception {
        mockMvc.perform(get("/api/ai-server/probe").header(SERVER_KEY_HEADER, "wrong-value"))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.errorCode").value("UNAUTHENTICATED"));
    }

    @Test
    void userJwtOnly_returns401OnAiServerPath() throws Exception {
        given(memberRepository.findByIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.of(Member.createMember(LoginType.GOOGLE, "google-uid", "soyeon@teeq.com", "소연")));
        String token = jwtProvider.issueAccessToken(MEMBER_ID);

        mockMvc.perform(get("/api/ai-server/probe").header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.errorCode").value("UNAUTHENTICATED"));
    }

    @Test
    void serverHeaderOnly_returns401OnOtherPath() throws Exception {
        mockMvc.perform(get("/api/probe").header(SERVER_KEY_HEADER, SERVER_KEY_VALUE))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.errorCode").value("UNAUTHENTICATED"));
    }

    @Test
    void validUserJwt_stillAllowsOtherPath() throws Exception {
        given(memberRepository.findByIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.of(Member.createMember(LoginType.GOOGLE, "google-uid", "soyeon@teeq.com", "소연")));
        String token = jwtProvider.issueAccessToken(MEMBER_ID);

        mockMvc.perform(get("/api/probe").header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
            .andExpect(status().isOk());
    }

    @RestController
    static class ProbeController {

        @GetMapping("/api/ai-server/probe")
        String aiServerProbe() {
            return "ok";
        }

        @GetMapping("/api/probe")
        String probe() {
            return "ok";
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
