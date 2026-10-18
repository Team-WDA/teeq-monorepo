package kr.co.teeq.api.auth.infrastructure.config;

import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.common.application.exception.GlobalExceptionHandler;
import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.repository.MemberRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
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
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

// 가입 미완료 회원(닉네임 NULL)의 유효한 Bearer 토큰으로 허용 목록과 그 외 경로를 구분하는지 확인한다.
// JWT 필터가 요청마다 회원을 다시 조회하므로 만료 토큰이 아니라 회원 상태로 차단이 갈린다
@WebMvcTest(controllers = SignupCompletionFilterTest.ProbeController.class)
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
    SignupCompletionFilterTest.ProbeController.class,
    SignupCompletionFilterTest.FixedClockConfig.class
})
class SignupCompletionFilterTest {

    private static final Instant NOW = Instant.parse("2026-10-18T00:00:00Z");
    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JwtProvider jwtProvider;

    @MockitoBean
    private MemberRepository memberRepository;

    private Member incompleteMember() {
        Member member = Member.createSocialMember(LoginType.APPLE, "apple-subject", "soyeon@privaterelay.appleid.com");
        ReflectionTestUtils.setField(member, "id", MEMBER_ID);
        return member;
    }

    private Member completedMember() {
        Member member = Member.builder()
            .email("soyeon@teeq.com")
            .password("encoded")
            .nickname("소연")
            .serviceTermsAgreed(true)
            .privacyPolicyAgreed(true)
            .build();
        ReflectionTestUtils.setField(member, "id", MEMBER_ID);
        return member;
    }

    private String bearerOf(Member member) {
        given(memberRepository.findByIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.of(member));
        return "Bearer " + jwtProvider.issueAccessToken(MEMBER_ID);
    }

    @Test
    void incompleteMember_allowListAndPublicPaths_passThroughFilter() throws Exception {
        String authorization = bearerOf(incompleteMember());
        List<MockHttpServletRequestBuilder> requests = List.of(
            get("/api/members/me"),
            post("/api/members/me/signup-completion"),
            post("/api/auth/logout"),
            delete("/api/members/me"),
            post("/api/auth/refresh"),
            get("/api/members/nickname-availability"),
            post("/api/members"),
            get("/docs/swagger-ui/index.html"));

        for (MockHttpServletRequestBuilder request : requests) {
            mockMvc.perform(request.header(HttpHeaders.AUTHORIZATION, authorization))
                .andExpect(status().isOk())
                .andExpect(content().string("passed"));
        }
    }

    @Test
    void incompleteMember_otherPaths_returns403SignupNotCompleted() throws Exception {
        String authorization = bearerOf(incompleteMember());
        List<MockHttpServletRequestBuilder> requests = List.of(
            get("/api/home"),
            patch("/api/members/me/nickname"),
            get("/api/members/me/signup-completion"));

        for (MockHttpServletRequestBuilder request : requests) {
            mockMvc.perform(request.header(HttpHeaders.AUTHORIZATION, authorization))
                .andExpect(status().isForbidden())
                .andExpect(content().contentType("application/json;charset=UTF-8"))
                .andExpect(jsonPath("$.errorCode").value("SIGNUP_NOT_COMPLETED"))
                .andExpect(jsonPath("$.errorMessage").value("가입을 완료해야 이용할 수 있습니다."));
        }
    }

    @Test
    void completedMember_otherPath_passesThroughFilter() throws Exception {
        String authorization = bearerOf(completedMember());

        mockMvc.perform(get("/api/home").header(HttpHeaders.AUTHORIZATION, authorization))
            .andExpect(status().isOk())
            .andExpect(content().string("passed"));
    }

    @Test
    void requestWithoutToken_isNotTouchedByFilter() throws Exception {
        mockMvc.perform(get("/api/home"))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.errorCode").value("UNAUTHENTICATED"));
        mockMvc.perform(get("/api/members/nickname-availability"))
            .andExpect(status().isOk())
            .andExpect(content().string("passed"));
    }

    @RestController
    static class ProbeController {

        private static final String PASSED = "passed";

        @GetMapping("/api/members/me")
        String getMe() {
            return PASSED;
        }

        @DeleteMapping("/api/members/me")
        String deleteAccount() {
            return PASSED;
        }

        @PostMapping("/api/members/me/signup-completion")
        String completeSignup() {
            return PASSED;
        }

        @GetMapping("/api/members/me/signup-completion")
        String getSignupCompletion() {
            return PASSED;
        }

        @PatchMapping("/api/members/me/nickname")
        String changeNickname() {
            return PASSED;
        }

        @PostMapping("/api/auth/logout")
        String logout() {
            return PASSED;
        }

        @PostMapping("/api/auth/refresh")
        String refresh() {
            return PASSED;
        }

        @GetMapping("/api/members/nickname-availability")
        String checkNicknameAvailability() {
            return PASSED;
        }

        @PostMapping("/api/members")
        String signUp() {
            return PASSED;
        }

        @GetMapping("/docs/swagger-ui/index.html")
        String swaggerUi() {
            return PASSED;
        }

        @GetMapping("/api/home")
        String home() {
            return PASSED;
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
