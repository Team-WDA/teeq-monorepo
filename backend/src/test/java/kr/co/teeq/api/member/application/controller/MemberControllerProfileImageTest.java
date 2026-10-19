package kr.co.teeq.api.member.application.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.willThrow;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.auth.infrastructure.config.JwtAccessDeniedHandler;
import kr.co.teeq.api.auth.infrastructure.config.JwtAuthenticationEntryPoint;
import kr.co.teeq.api.auth.infrastructure.config.JwtProvider;
import kr.co.teeq.api.auth.infrastructure.config.SecurityConfig;
import kr.co.teeq.api.common.application.exception.GlobalExceptionHandler;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.application.dto.response.MemberResponse;
import kr.co.teeq.api.member.application.service.MemberService;
import kr.co.teeq.api.member.application.service.ProfileImageService;
import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.repository.MemberRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.ImportAutoConfiguration;
import org.springframework.boot.autoconfigure.aop.AopAutoConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(controllers = MemberController.class)
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
    MemberController.class,
    MemberControllerProfileImageTest.FixedClockConfig.class
})
class MemberControllerProfileImageTest {

    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final String PATH = "/api/members/me/profile-image";

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JwtProvider jwtProvider;

    @MockitoBean
    private MemberRepository memberRepository;

    @MockitoBean
    private MemberService memberService;

    @MockitoBean
    private ProfileImageService profileImageService;

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

    private MockMultipartFile imagePart() {
        return new MockMultipartFile("image", "photo.png", "image/png", new byte[] {1, 2, 3});
    }

    @Test
    void replace_withoutToken_returns401() throws Exception {
        mockMvc.perform(multipart(HttpMethod.PUT, PATH).file(imagePart()))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.errorCode").value("UNAUTHENTICATED"));
    }

    @Test
    void delete_withoutToken_returns401() throws Exception {
        mockMvc.perform(delete(PATH))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.errorCode").value("UNAUTHENTICATED"));
    }

    @Test
    void replace_withoutImagePart_returns400() throws Exception {
        mockMvc.perform(multipart(HttpMethod.PUT, PATH).header(HttpHeaders.AUTHORIZATION, bearer()))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errorCode").value("INVALID_REQUEST"));
    }

    @Test
    void replace_whenServiceRejectsOversizedFile_returns413WithErrorBody() throws Exception {
        willThrow(new CustomException(ErrorCode.PROFILE_IMAGE_TOO_LARGE))
            .given(profileImageService).replace(any(), any());

        mockMvc.perform(multipart(HttpMethod.PUT, PATH).file(imagePart()).header(HttpHeaders.AUTHORIZATION, bearer()))
            .andExpect(status().isPayloadTooLarge())
            .andExpect(jsonPath("$.errorCode").value("PROFILE_IMAGE_TOO_LARGE"));
    }

    @Test
    void replace_success_returns200WithUpdatedMember() throws Exception {
        given(memberService.getMe(any())).willReturn(new MemberResponse(
            MEMBER_ID, "soyeon@teeq.com", "소연", false, LoginType.EMAIL,
            "https://api.teeq.co.kr/media/profile-images/key.png"));

        mockMvc.perform(multipart(HttpMethod.PUT, PATH).file(imagePart()).header(HttpHeaders.AUTHORIZATION, bearer()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.profileImageUrl").value("https://api.teeq.co.kr/media/profile-images/key.png"));
        verify(profileImageService).replace(any(), any());
    }

    @Test
    void delete_success_returns204() throws Exception {
        mockMvc.perform(delete(PATH).header(HttpHeaders.AUTHORIZATION, bearer()))
            .andExpect(status().isNoContent());
        verify(profileImageService).delete(MEMBER_ID);
    }

    @TestConfiguration(proxyBeanMethods = false)
    static class FixedClockConfig {

        @Bean
        Clock clock() {
            return Clock.fixed(Instant.parse("2026-10-17T00:00:00Z"), ZoneOffset.UTC);
        }

    }

}
