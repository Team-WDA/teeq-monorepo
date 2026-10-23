package kr.co.teeq.api.support.application.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
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
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.repository.MemberRepository;
import kr.co.teeq.api.support.application.dto.response.BugReportCreateResponse;
import kr.co.teeq.api.support.application.service.BugReportService;
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
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(controllers = BugReportController.class)
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
    BugReportController.class,
    BugReportControllerTest.FixedClockConfig.class
})
class BugReportControllerTest {

    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final UUID BUG_REPORT_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5c");
    private static final String PATH = "/api/bug-reports";

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JwtProvider jwtProvider;

    @MockitoBean
    private MemberRepository memberRepository;

    @MockitoBean
    private BugReportService bugReportService;

    private String bearer() {
        Member member = Member.createMember(LoginType.GOOGLE, "google-uid", "soyeon@teeq.com", "소연");
        ReflectionTestUtils.setField(member, "id", MEMBER_ID);
        given(memberRepository.findByIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.of(member));
        return "Bearer " + jwtProvider.issueAccessToken(MEMBER_ID);
    }

    private String requestJson(String content) {
        return """
            {"source":"USER","content":"%s",
             "environment":{"appVersion":"1.2.3","platform":"ANDROID","osVersion":"Android 15","deviceModel":"Pixel 9"}}
            """.formatted(content);
    }

    private MockMultipartFile requestPart(String json, String contentType) {
        return new MockMultipartFile("request", "request.json", contentType, json.getBytes());
    }

    private MockMultipartFile imagePart() {
        return new MockMultipartFile("images", "photo.png", "image/png", new byte[] {1, 2, 3});
    }

    @Test
    void create_withoutToken_returns401() throws Exception {
        mockMvc.perform(multipart(PATH).file(requestPart(requestJson("앱이 멈춰요"), MediaType.APPLICATION_JSON_VALUE)))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.errorCode").value("UNAUTHENTICATED"));
    }

    @Test
    void create_success_returns201WithBugReportId() throws Exception {
        given(bugReportService.create(any(), any(), any())).willReturn(new BugReportCreateResponse(BUG_REPORT_ID));

        mockMvc.perform(multipart(PATH)
                .file(requestPart(requestJson("앱이 멈춰요"), MediaType.APPLICATION_JSON_VALUE))
                .file(imagePart())
                .header(HttpHeaders.AUTHORIZATION, bearer()))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.bugReportId").value(BUG_REPORT_ID.toString()));
        verify(bugReportService).create(
            argThat(member -> MEMBER_ID.equals(member.getId())),
            argThat(request -> "앱이 멈춰요".equals(request.content())),
            argThat(images -> images.size() == 1));
    }

    @Test
    void create_contentOver2000Characters_returns400InvalidRequest() throws Exception {
        mockMvc.perform(multipart(PATH)
                .file(requestPart(requestJson("가".repeat(2001)), MediaType.APPLICATION_JSON_VALUE))
                .header(HttpHeaders.AUTHORIZATION, bearer()))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errorCode").value("INVALID_REQUEST"));
        verifyNoInteractions(bugReportService);
    }

    @Test
    void create_withoutRequestPart_returns400InvalidRequest() throws Exception {
        mockMvc.perform(multipart(PATH).file(imagePart()).header(HttpHeaders.AUTHORIZATION, bearer()))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errorCode").value("INVALID_REQUEST"));
    }

    // 파트에 content type이 없으면 octet-stream으로 읽혀 JSON으로 변환되지 않는다. 앱은 반드시 application/json을 붙여야 한다
    @Test
    void create_requestPartWithoutContentType_returns415() throws Exception {
        mockMvc.perform(multipart(PATH)
                .file(requestPart(requestJson("앱이 멈춰요"), MediaType.APPLICATION_OCTET_STREAM_VALUE))
                .header(HttpHeaders.AUTHORIZATION, bearer()))
            .andExpect(status().isUnsupportedMediaType())
            .andExpect(jsonPath("$.errorCode").value("UNSUPPORTED_MEDIA_TYPE"));
    }

    @Test
    void create_whenServiceRejectsImages_returnsErrorBody() throws Exception {
        given(bugReportService.create(any(), any(), any()))
            .willThrow(new CustomException(ErrorCode.BUG_REPORT_IMAGE_TOO_MANY));

        mockMvc.perform(multipart(PATH)
                .file(requestPart(requestJson("앱이 멈춰요"), MediaType.APPLICATION_JSON_VALUE))
                .header(HttpHeaders.AUTHORIZATION, bearer()))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errorCode").value("BUG_REPORT_IMAGE_TOO_MANY"));
    }

    @TestConfiguration(proxyBeanMethods = false)
    static class FixedClockConfig {

        @Bean
        Clock clock() {
            return Clock.fixed(Instant.parse("2026-10-22T00:00:00Z"), ZoneOffset.UTC);
        }

    }

}
