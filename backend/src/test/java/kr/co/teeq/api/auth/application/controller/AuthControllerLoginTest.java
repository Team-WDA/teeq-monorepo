package kr.co.teeq.api.auth.application.controller;

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
import kr.co.teeq.api.auth.application.dto.response.AuthResponse;
import kr.co.teeq.api.auth.application.service.AuthService;
import kr.co.teeq.api.auth.infrastructure.config.JwtAccessDeniedHandler;
import kr.co.teeq.api.auth.infrastructure.config.JwtAuthenticationEntryPoint;
import kr.co.teeq.api.auth.infrastructure.config.JwtProvider;
import kr.co.teeq.api.auth.infrastructure.config.SecurityConfig;
import kr.co.teeq.api.common.application.exception.GlobalExceptionHandler;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.member.core.repository.MemberRepository;
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
    AuthControllerLoginTest.FixedClockConfig.class
})
class AuthControllerLoginTest {

    private static final Instant NOW = Instant.parse("2026-10-17T00:00:00Z");
    private static final String PATH = "/api/auth/login";
    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private MemberRepository memberRepository;

    @MockitoBean
    private AuthService authService;

    private static final String SIGNUP_PATH = "/api/auth/signup";
    private static final String LOGIN_BODY = "{\"credential\":\"token\"}";
    private static final String SIGNUP_BODY = "{\"credential\":\"token\",\"nickname\":\"소연\","
        + "\"serviceTermsAgreed\":true,\"privacyPolicyAgreed\":true}";

    private AuthResponse response() {
        return new AuthResponse("access", "refresh", MEMBER_ID, "소연", false, LoginType.GOOGLE, null);
    }

    private void assertInvalidRequest(String path, String body) throws Exception {
        mockMvc.perform(post(path).contentType(MediaType.APPLICATION_JSON).content(body))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errorCode").value("INVALID_REQUEST"));
        verifyNoInteractions(authService);
    }

    @Test
    void login_existingMember_returns200WithoutAuthentication() throws Exception {
        given(authService.login(any())).willReturn(response());

        mockMvc.perform(post(PATH).contentType(MediaType.APPLICATION_JSON).content(LOGIN_BODY))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.loginType").value("GOOGLE"))
            .andExpect(jsonPath("$.nickname").value("소연"))
            .andExpect(jsonPath("$.profileImageUrl").doesNotExist());
    }

    @Test
    void login_signupRequired_returns404() throws Exception {
        given(authService.login(any())).willThrow(new CustomException(ErrorCode.AUTH_SIGNUP_REQUIRED));

        mockMvc.perform(post(PATH).contentType(MediaType.APPLICATION_JSON).content(LOGIN_BODY))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.errorCode").value("AUTH_SIGNUP_REQUIRED"));
    }

    @Test
    void login_invalidToken_returns401() throws Exception {
        given(authService.login(any())).willThrow(new CustomException(ErrorCode.AUTH_TOKEN_INVALID));

        mockMvc.perform(post(PATH).contentType(MediaType.APPLICATION_JSON).content(LOGIN_BODY))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.errorCode").value("AUTH_TOKEN_INVALID"));
    }

    @Test
    void login_blankOrTooLongCredential_returns400() throws Exception {
        assertInvalidRequest(PATH, "{\"credential\":\" \"}");
        assertInvalidRequest(PATH, "{}");
        assertInvalidRequest(PATH, "{\"credential\":\"" + "a".repeat(4097) + "\"}");
    }

    @Test
    void signUp_returns201WithoutAuthentication() throws Exception {
        given(authService.signUp(any())).willReturn(response());

        mockMvc.perform(post(SIGNUP_PATH).contentType(MediaType.APPLICATION_JSON).content(SIGNUP_BODY))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.loginType").value("GOOGLE"));
    }

    @Test
    void signUp_alreadyRegistered_returns409StateConflict() throws Exception {
        given(authService.signUp(any())).willThrow(new CustomException(ErrorCode.STATE_CONFLICT));

        mockMvc.perform(post(SIGNUP_PATH).contentType(MediaType.APPLICATION_JSON).content(SIGNUP_BODY))
            .andExpect(status().isConflict())
            .andExpect(jsonPath("$.errorCode").value("STATE_CONFLICT"));
    }

    @Test
    void signUp_duplicateNickname_returns409() throws Exception {
        given(authService.signUp(any())).willThrow(new CustomException(ErrorCode.DUPLICATE_NICKNAME));

        mockMvc.perform(post(SIGNUP_PATH).contentType(MediaType.APPLICATION_JSON).content(SIGNUP_BODY))
            .andExpect(status().isConflict())
            .andExpect(jsonPath("$.errorCode").value("DUPLICATE_NICKNAME"));
    }

    @Test
    void signUp_invalidInput_returns400() throws Exception {
        assertInvalidRequest(SIGNUP_PATH, SIGNUP_BODY.replace("\"token\"", "\" \""));
        assertInvalidRequest(SIGNUP_PATH, SIGNUP_BODY.replace("소연", "abc"));
        assertInvalidRequest(SIGNUP_PATH, SIGNUP_BODY.replace("\"serviceTermsAgreed\":true", "\"serviceTermsAgreed\":false"));
        assertInvalidRequest(SIGNUP_PATH, SIGNUP_BODY.replace("\"privacyPolicyAgreed\":true", "\"privacyPolicyAgreed\":false"));
    }

    @TestConfiguration(proxyBeanMethods = false)
    static class FixedClockConfig {

        @Bean
        Clock clock() {
            return Clock.fixed(NOW, ZoneOffset.UTC);
        }

    }

}
