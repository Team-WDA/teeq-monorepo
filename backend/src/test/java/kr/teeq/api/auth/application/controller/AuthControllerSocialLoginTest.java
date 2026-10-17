package kr.teeq.api.auth.application.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.UUID;
import kr.teeq.api.auth.application.dto.response.AuthResponse;
import kr.teeq.api.auth.application.service.AuthService;
import kr.teeq.api.auth.application.service.SocialLoginResult;
import kr.teeq.api.auth.infrastructure.config.JwtAccessDeniedHandler;
import kr.teeq.api.auth.infrastructure.config.JwtAuthenticationEntryPoint;
import kr.teeq.api.auth.infrastructure.config.JwtProvider;
import kr.teeq.api.auth.infrastructure.config.SecurityConfig;
import kr.teeq.api.common.application.exception.GlobalExceptionHandler;
import kr.teeq.api.common.core.exception.CustomException;
import kr.teeq.api.common.core.exception.ErrorCode;
import kr.teeq.api.member.core.constant.LoginType;
import kr.teeq.api.member.core.repository.MemberRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.ImportAutoConfiguration;
import org.springframework.boot.autoconfigure.aop.AopAutoConfiguration;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(controllers = AuthController.class)
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
    AuthController.class,
    AuthControllerSocialLoginTest.FixedClockConfig.class
})
class AuthControllerSocialLoginTest {

    private static final Instant NOW = Instant.parse("2026-10-17T00:00:00Z");
    private static final String PATH = "/api/auth/social-login";
    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private MemberRepository memberRepository;

    @MockitoBean
    private AuthService authService;

    private SocialLoginResult result(boolean created) {
        return new SocialLoginResult(
            new AuthResponse("access", "refresh", MEMBER_ID, "소연", false, LoginType.APPLE, null), created);
    }

    private void assertInvalidRequest(String body) throws Exception {
        mockMvc.perform(post(PATH).contentType(MediaType.APPLICATION_JSON).content(body))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errorCode").value("INVALID_REQUEST"));
        verifyNoInteractions(authService);
    }

    @Test
    void newMember_returns201WithoutAuthentication() throws Exception {
        given(authService.socialLogin(any())).willReturn(result(true));

        mockMvc.perform(post(PATH).contentType(MediaType.APPLICATION_JSON)
                .content("{\"socialType\":\"APPLE\",\"credential\":\"token\",\"nickname\":\"소연\","
                    + "\"serviceTermsAgreed\":true,\"privacyPolicyAgreed\":true}"))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.loginType").value("APPLE"))
            .andExpect(jsonPath("$.profileImageUrl").doesNotExist());
    }

    @Test
    void existingMember_returns200() throws Exception {
        given(authService.socialLogin(any())).willReturn(result(false));

        mockMvc.perform(post(PATH).contentType(MediaType.APPLICATION_JSON)
                .content("{\"socialType\":\"APPLE\",\"credential\":\"token\"}"))
            .andExpect(status().isOk());
    }

    @Test
    void serviceError_isConvertedToErrorResponse() throws Exception {
        given(authService.socialLogin(any())).willThrow(new CustomException(ErrorCode.SOCIAL_SIGNUP_REQUIRED));

        mockMvc.perform(post(PATH).contentType(MediaType.APPLICATION_JSON)
                .content("{\"socialType\":\"APPLE\",\"credential\":\"token\"}"))
            .andExpect(status().isConflict())
            .andExpect(jsonPath("$.errorCode").value("SOCIAL_SIGNUP_REQUIRED"));
    }

    @Test
    void missingSocialTypeOrBlankCredential_returns400() throws Exception {
        assertInvalidRequest("{\"credential\":\"token\"}");
        assertInvalidRequest("{\"socialType\":\"APPLE\",\"credential\":\" \"}");
    }

    @Test
    void tooLongCredential_returns400() throws Exception {
        assertInvalidRequest("{\"socialType\":\"APPLE\",\"credential\":\"" + "a".repeat(4097) + "\"}");
    }

    @Test
    void invalidNicknameOrAgreementFalse_returns400() throws Exception {
        assertInvalidRequest("{\"socialType\":\"APPLE\",\"credential\":\"token\",\"nickname\":\"a\"}");
        assertInvalidRequest("{\"socialType\":\"APPLE\",\"credential\":\"token\",\"serviceTermsAgreed\":false}");
        assertInvalidRequest("{\"socialType\":\"APPLE\",\"credential\":\"token\",\"privacyPolicyAgreed\":false}");
    }

    @Test
    void unknownSocialType_returns400MalformedBody() throws Exception {
        mockMvc.perform(post(PATH).contentType(MediaType.APPLICATION_JSON)
                .content("{\"socialType\":\"KAKAO\",\"credential\":\"token\"}"))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errorCode").value("MALFORMED_REQUEST_BODY"));
    }

    @TestConfiguration(proxyBeanMethods = false)
    static class FixedClockConfig {

        @Bean
        Clock clock() {
            return Clock.fixed(NOW, ZoneOffset.UTC);
        }

    }

}
