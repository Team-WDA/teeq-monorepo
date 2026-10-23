package kr.co.teeq.api.feedback.application.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.auth.infrastructure.config.JwtAccessDeniedHandler;
import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.auth.infrastructure.config.JwtAuthenticationEntryPoint;
import kr.co.teeq.api.auth.infrastructure.config.JwtProvider;
import kr.co.teeq.api.auth.infrastructure.config.SecurityConfig;
import kr.co.teeq.api.common.application.exception.GlobalExceptionHandler;
import kr.co.teeq.api.feedback.application.dto.request.DetailedFeedbackRequest;
import kr.co.teeq.api.feedback.application.dto.request.RequiredFeedbackRequest;
import kr.co.teeq.api.feedback.application.dto.response.FeedbackStatusResponse;
import kr.co.teeq.api.feedback.application.dto.response.RequiredFeedbackResponse;
import kr.co.teeq.api.feedback.application.service.CallFeedbackService;
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

@WebMvcTest(controllers = FeedbackController.class)
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
    FeedbackController.class,
    FeedbackControllerTest.FixedClockConfig.class
})
class FeedbackControllerTest {

    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final String BASE_PATH = "/api/calls/session-1";
    private static final String VALID_REQUIRED_BODY = """
        {"rating": 4, "revisitIntention": "YES", "previousCallRecall": "REMEMBERED", "awkwardMoments": ["CUT"]}""";
    private static final String VALID_DETAILED_BODY = """
        {"timingScore": 4, "personaFitScore": 5, "memoryScore": 3, "memoryNotApplicable": false,
         "empathyTrustScore": 4, "personalComfortScore": 3, "storageComfortScore": 2,
         "startReasons": ["NEED_TO_TALK"]}""";

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JwtProvider jwtProvider;

    @MockitoBean
    private MemberRepository memberRepository;

    @MockitoBean
    private CallFeedbackService callFeedbackService;

    private String bearer() {
        Member member = Member.createSocialMember(LoginType.GOOGLE, "google-uid", "soyeon@teeq.com", "소연");
        ReflectionTestUtils.setField(member, "id", MEMBER_ID);
        given(memberRepository.findByIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.of(member));
        return "Bearer " + jwtProvider.issueAccessToken(MEMBER_ID);
    }

    @Test
    void noToken_returns401() throws Exception {
        mockMvc.perform(post(BASE_PATH + "/required-feedback")
                .contentType(MediaType.APPLICATION_JSON).content(VALID_REQUIRED_BODY))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.errorCode").value("UNAUTHENTICATED"));
        verifyNoInteractions(callFeedbackService);
    }

    @Test
    void getFeedbackStatus_returns200() throws Exception {
        given(callFeedbackService.getStatus(any(Member.class), eq("session-1")))
            .willReturn(new FeedbackStatusResponse(3, true, false));

        mockMvc.perform(get(BASE_PATH + "/feedback-status").header(HttpHeaders.AUTHORIZATION, bearer()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.callIndex").value(3))
            .andExpect(jsonPath("$.previousCallRecallRequired").value(true))
            .andExpect(jsonPath("$.requiredFeedbackSubmitted").value(false));
    }

    @Test
    void submitRequiredFeedback_returns201WithInvitation() throws Exception {
        given(callFeedbackService.submitRequired(
            any(Member.class), eq("session-1"), any(RequiredFeedbackRequest.class)))
            .willReturn(new RequiredFeedbackResponse(true));

        mockMvc.perform(post(BASE_PATH + "/required-feedback").header(HttpHeaders.AUTHORIZATION, bearer())
                .contentType(MediaType.APPLICATION_JSON).content(VALID_REQUIRED_BODY))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.detailedFeedbackInvited").value(true));
    }

    @Test
    void submitRequiredFeedback_invalidRating_returns400InvalidRequest() throws Exception {
        mockMvc.perform(post(BASE_PATH + "/required-feedback").header(HttpHeaders.AUTHORIZATION, bearer())
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"rating": 9, "revisitIntention": "YES", "awkwardMoments": ["CUT"]}"""))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errorCode").value("INVALID_REQUEST"));
        verifyNoInteractions(callFeedbackService);
    }

    @Test
    void submitRequiredFeedback_unknownEnumValue_returns400MalformedRequestBody() throws Exception {
        mockMvc.perform(post(BASE_PATH + "/required-feedback").header(HttpHeaders.AUTHORIZATION, bearer())
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"rating": 4, "revisitIntention": "MAYBE", "awkwardMoments": ["CUT"]}"""))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errorCode").value("MALFORMED_REQUEST_BODY"));
        verifyNoInteractions(callFeedbackService);
    }

    @Test
    void submitDetailedFeedback_returns201WithoutBody() throws Exception {
        mockMvc.perform(post(BASE_PATH + "/detailed-feedback").header(HttpHeaders.AUTHORIZATION, bearer())
                .contentType(MediaType.APPLICATION_JSON).content(VALID_DETAILED_BODY))
            .andExpect(status().isCreated())
            .andExpect(content().string(""));
        verify(callFeedbackService).submitDetailed(any(Member.class), eq("session-1"),
            any(DetailedFeedbackRequest.class));
    }

    @Test
    void submitDetailedFeedback_missingMemoryNotApplicable_returns400InvalidRequest() throws Exception {
        mockMvc.perform(post(BASE_PATH + "/detailed-feedback").header(HttpHeaders.AUTHORIZATION, bearer())
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"timingScore": 4, "personaFitScore": 5, "memoryScore": 3,
                     "empathyTrustScore": 4, "personalComfortScore": 3, "storageComfortScore": 2,
                     "startReasons": ["NEED_TO_TALK"]}"""))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errorCode").value("INVALID_REQUEST"));
        verifyNoInteractions(callFeedbackService);
    }

    @Test
    void submitDetailedFeedback_unknownEnumValue_returns400MalformedRequestBody() throws Exception {
        mockMvc.perform(post(BASE_PATH + "/detailed-feedback").header(HttpHeaders.AUTHORIZATION, bearer())
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"timingScore": 4, "personaFitScore": 5, "memoryScore": 3, "memoryNotApplicable": false,
                     "empathyTrustScore": 4, "personalComfortScore": 3, "storageComfortScore": 2,
                     "startReasons": ["BECAUSE"]}"""))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errorCode").value("MALFORMED_REQUEST_BODY"));
        verifyNoInteractions(callFeedbackService);
    }

    @TestConfiguration(proxyBeanMethods = false)
    static class FixedClockConfig {

        @Bean
        Clock clock() {
            return Clock.fixed(Instant.parse("2026-10-16T00:00:00Z"), ZoneOffset.UTC);
        }

    }

}
