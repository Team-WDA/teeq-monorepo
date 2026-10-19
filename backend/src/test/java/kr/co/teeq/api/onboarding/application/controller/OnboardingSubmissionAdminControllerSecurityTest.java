package kr.co.teeq.api.onboarding.application.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verify;
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
import kr.co.teeq.api.auth.infrastructure.config.JwtAccessDeniedHandler;
import kr.co.teeq.api.auth.infrastructure.config.JwtAuthenticationEntryPoint;
import kr.co.teeq.api.auth.infrastructure.config.JwtProvider;
import kr.co.teeq.api.auth.infrastructure.config.SecurityConfig;
import kr.co.teeq.api.common.application.exception.GlobalExceptionHandler;
import kr.co.teeq.api.member.core.constant.Role;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.repository.MemberRepository;
import kr.co.teeq.api.onboarding.application.dto.request.OnboardingSubmissionSearchRequest;
import kr.co.teeq.api.onboarding.application.dto.response.OnboardingSubmissionPageResponse;
import kr.co.teeq.api.onboarding.application.service.OnboardingSubmissionQueryService;
import kr.co.teeq.api.onboarding.core.constant.OnboardingOption;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.ImportAutoConfiguration;
import org.springframework.boot.autoconfigure.aop.AopAutoConfiguration;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(controllers = OnboardingSubmissionAdminController.class)
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
    OnboardingSubmissionAdminController.class,
    OnboardingSubmissionAdminControllerSecurityTest.FixedClockConfig.class
})
class OnboardingSubmissionAdminControllerSecurityTest {

    private static final Instant NOW = Instant.parse("2026-10-19T00:00:00Z");
    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final String PATH = "/api/admin/onboarding-submissions";

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JwtProvider jwtProvider;

    @MockitoBean
    private MemberRepository memberRepository;

    @MockitoBean
    private OnboardingSubmissionQueryService onboardingSubmissionQueryService;

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

    private void stubEmptyPage() {
        given(onboardingSubmissionQueryService.search(any(), any()))
            .willReturn(new OnboardingSubmissionPageResponse(List.of(), 0, 20, 0));
    }

    @Test
    void search_withoutToken_returns401() throws Exception {
        mockMvc.perform(get(PATH))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.errorCode").value("UNAUTHENTICATED"));
    }

    @Test
    void search_asUser_returns403() throws Exception {
        mockMvc.perform(get(PATH).header(HttpHeaders.AUTHORIZATION, bearerFor(Role.USER)))
            .andExpect(status().isForbidden())
            .andExpect(jsonPath("$.errorCode").value("ACCESS_DENIED"));
    }

    @Test
    void search_asAdmin_returns200AndBody() throws Exception {
        given(onboardingSubmissionQueryService.search(any(), any()))
            .willReturn(new OnboardingSubmissionPageResponse(List.of(), 1, 20, 42));

        mockMvc.perform(get(PATH).header(HttpHeaders.AUTHORIZATION, bearerFor(Role.ADMIN)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.items").isArray())
            .andExpect(jsonPath("$.page").value(1))
            .andExpect(jsonPath("$.size").value(20))
            .andExpect(jsonPath("$.totalElements").value(42));
    }

    @Test
    void search_asAdmin_passesQueryConditionsToService() throws Exception {
        stubEmptyPage();

        mockMvc.perform(get(PATH + "?memberId=" + MEMBER_ID + "&from=2026-10-01&to=2026-10-31"
                + "&optionCode=RELATIONSHIP_CLOSE_FRIEND&active=true")
                .header(HttpHeaders.AUTHORIZATION, bearerFor(Role.ADMIN)))
            .andExpect(status().isOk());

        ArgumentCaptor<OnboardingSubmissionSearchRequest> captor =
            ArgumentCaptor.forClass(OnboardingSubmissionSearchRequest.class);
        verify(onboardingSubmissionQueryService).search(captor.capture(), any());
        assertThat(captor.getValue()).isEqualTo(new OnboardingSubmissionSearchRequest(
            MEMBER_ID, LocalDate.of(2026, 10, 1), LocalDate.of(2026, 10, 31),
            OnboardingOption.RELATIONSHIP_CLOSE_FRIEND, true));
    }

    @Test
    void search_oversizedPage_isCappedAtMaxPageSize() throws Exception {
        stubEmptyPage();

        mockMvc.perform(get(PATH + "?size=1000").header(HttpHeaders.AUTHORIZATION, bearerFor(Role.ADMIN)))
            .andExpect(status().isOk());

        ArgumentCaptor<Pageable> captor = ArgumentCaptor.forClass(Pageable.class);
        verify(onboardingSubmissionQueryService).search(any(), captor.capture());
        assertThat(captor.getValue().getPageSize()).isLessThanOrEqualTo(100);
    }

    @Test
    void search_asAdmin_withUnknownSort_returns200() throws Exception {
        stubEmptyPage();

        mockMvc.perform(get(PATH + "?sort=없는필드,desc").header(HttpHeaders.AUTHORIZATION, bearerFor(Role.ADMIN)))
            .andExpect(status().isOk());

        verify(onboardingSubmissionQueryService).search(any(), any());
    }

    @Test
    void search_unknownOptionCode_returns400() throws Exception {
        mockMvc.perform(get(PATH + "?optionCode=NOT_AN_OPTION").header(HttpHeaders.AUTHORIZATION, bearerFor(Role.ADMIN)))
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
