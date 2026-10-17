package kr.teeq.api.home.application.controller;

import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kr.teeq.api.auth.infrastructure.config.JwtAccessDeniedHandler;
import kr.teeq.api.auth.infrastructure.config.JwtAuthenticationEntryPoint;
import kr.teeq.api.auth.infrastructure.config.JwtProvider;
import kr.teeq.api.auth.infrastructure.config.SecurityConfig;
import kr.teeq.api.call.application.dto.response.CallLimitStatusResponse;
import kr.teeq.api.common.application.exception.GlobalExceptionHandler;
import kr.teeq.api.home.application.dto.response.HomeResponse;
import kr.teeq.api.home.application.service.HomeService;
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

@WebMvcTest(controllers = HomeController.class)
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
    HomeController.class,
    HomeControllerTest.FixedClockConfig.class
})
class HomeControllerTest {

    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JwtProvider jwtProvider;

    @MockitoBean
    private MemberRepository memberRepository;

    @MockitoBean
    private HomeService homeService;

    private String bearer() {
        Member member = Member.builder()
            .email("soyeon@teeq.com")
            .password("encoded")
            .nickname("소연")
            .serviceTermsAgreed(true)
            .privacyPolicyAgreed(true)
            .build();
        ReflectionTestUtils.setField(member, "id", MEMBER_ID);
        given(memberRepository.findByIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.of(member));
        return "Bearer " + jwtProvider.issueAccessToken(MEMBER_ID);
    }

    @Test
    void noToken_returns401() throws Exception {
        mockMvc.perform(get("/api/home"))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.errorCode").value("UNAUTHENTICATED"));
        verifyNoInteractions(homeService);
    }

    @Test
    void getHome_returns200() throws Exception {
        given(homeService.getHome(MEMBER_ID, "소연")).willReturn(new HomeResponse("티큐",
            List.of("다정한", "차분한", "든든한"), "소연아,\n오늘 하루 어땠어?",
            new CallLimitStatusResponse(300, 1500, 1200, true), null));

        mockMvc.perform(get("/api/home").header(HttpHeaders.AUTHORIZATION, bearer()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.characterName").value("티큐"))
            .andExpect(jsonPath("$.personalityTags[0]").value("다정한"))
            .andExpect(jsonPath("$.greeting").value("소연아,\n오늘 하루 어땠어?"))
            .andExpect(jsonPath("$.callLimit.canStart").value(true))
            .andExpect(jsonPath("$.pendingFeedback").value(org.hamcrest.Matchers.nullValue()));
    }

    @TestConfiguration
    static class FixedClockConfig {

        @Bean
        Clock clock() {
            return Clock.fixed(Instant.parse("2026-10-16T00:00:00Z"), ZoneOffset.UTC);
        }

    }

}
