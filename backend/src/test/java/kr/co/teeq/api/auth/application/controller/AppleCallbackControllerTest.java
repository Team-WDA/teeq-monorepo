package kr.co.teeq.api.auth.application.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Map;
import kr.co.teeq.api.auth.application.service.AuthService;
import kr.co.teeq.api.auth.infrastructure.config.JwtAccessDeniedHandler;
import kr.co.teeq.api.auth.infrastructure.config.JwtAuthenticationEntryPoint;
import kr.co.teeq.api.auth.infrastructure.config.JwtProvider;
import kr.co.teeq.api.auth.infrastructure.config.SecurityConfig;
import kr.co.teeq.api.common.application.exception.GlobalExceptionHandler;
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
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.util.UriComponentsBuilder;

@WebMvcTest(controllers = AppleCallbackController.class)
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
    AppleCallbackController.class,
    AppleCallbackControllerTest.FixedClockConfig.class
})
class AppleCallbackControllerTest {

    private static final String PATH = "/api/auth/apple/callback";
    private static final String LOCATION_PREFIX = "intent://callback?";
    private static final String LOCATION_SUFFIX = "#Intent;package=kr.co.teeq.app;scheme=signinwithapple;end";

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private MemberRepository memberRepository;

    @MockitoBean
    private AuthService authService;

    private String callbackLocation(String... formPairs) throws Exception {
        var request = post(PATH).contentType(MediaType.APPLICATION_FORM_URLENCODED);
        for (int index = 0; index < formPairs.length; index += 2) {
            request.param(formPairs[index], formPairs[index + 1]);
        }
        var result = mockMvc.perform(request).andExpect(status().isFound()).andReturn();
        return result.getResponse().getHeader(HttpHeaders.LOCATION);
    }

    private Map<String, String> decodedQuery(String location) {
        String query = location.substring(LOCATION_PREFIX.length(), location.indexOf('#'));
        return UriComponentsBuilder.fromUri(URI.create("intent://callback?" + query)).build().getQueryParams()
            .toSingleValueMap().entrySet().stream()
            .collect(java.util.stream.Collectors.toMap(Map.Entry::getKey,
                entry -> java.net.URLDecoder.decode(entry.getValue(), StandardCharsets.UTF_8)));
    }

    @Test
    void callback_forwardsAllowedParametersAsIntentRedirect() throws Exception {
        String location = callbackLocation("code", "c", "id_token", "t", "state", "s");

        assertThat(location).startsWith(LOCATION_PREFIX).endsWith(LOCATION_SUFFIX);
        assertThat(decodedQuery(location)).containsExactlyInAnyOrderEntriesOf(
            Map.of("code", "c", "id_token", "t", "state", "s"));
    }

    @Test
    void callback_dropsUnknownParameters() throws Exception {
        String location = callbackLocation("code", "c", "foo", "bar");

        assertThat(location).doesNotContain("foo").doesNotContain("bar");
        assertThat(decodedQuery(location)).containsExactlyEntriesOf(Map.of("code", "c"));
    }

    @Test
    void callback_forwardsErrorWithoutIdToken() throws Exception {
        String location = callbackLocation("error", "user_cancelled_authorize");

        assertThat(location).startsWith(LOCATION_PREFIX).endsWith(LOCATION_SUFFIX);
        assertThat(decodedQuery(location)).containsExactlyEntriesOf(Map.of("error", "user_cancelled_authorize"));
    }

    @Test
    void callback_encodesUserJson() throws Exception {
        String userJson = "{\"name\":{\"firstName\":\"a\"}}";

        String location = callbackLocation("user", userJson);

        assertThat(location).doesNotContain("{").doesNotContain("\"");
        assertThat(decodedQuery(location)).containsExactlyEntriesOf(Map.of("user", userJson));
    }

    @TestConfiguration
    static class FixedClockConfig {

        @Bean
        Clock clock() {
            return Clock.fixed(Instant.parse("2026-10-17T00:00:00Z"), ZoneOffset.UTC);
        }

    }

}
