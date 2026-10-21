package kr.co.teeq.api.home.infrastructure.adapter;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.hamcrest.Matchers.nullValue;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.header;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.jsonPath;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withServerError;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

import java.time.Instant;
import java.util.UUID;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.common.infrastructure.properties.AiServerProperties;
import kr.co.teeq.api.home.core.port.GreetingRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

class AiServerGreetingGenerationAdapterTest {

    private static final String BASE_URL = "http://ai-server.test";
    private static final String HEADER_NAME = "X-Teeq-Server-Key";
    private static final String HEADER_VALUE = "dummy-server-key";
    private static final String PERSONA_ID = "persona-1";
    private static final Instant LAST_GREETED_AT = Instant.parse("2026-10-20T15:00:00Z");

    private MockRestServiceServer server;
    private AiServerGreetingGenerationAdapter adapter;

    @BeforeEach
    void setUp() {
        RestClient.Builder builder = RestClient.builder().baseUrl(BASE_URL);
        server = MockRestServiceServer.bindTo(builder).build();
        AiServerProperties properties = new AiServerProperties(BASE_URL, HEADER_NAME, HEADER_VALUE);
        adapter = new AiServerGreetingGenerationAdapter(builder.build(), properties);
    }

    @Test
    void 정상_응답이면_message만_돌려주고_요청_본문을_camelCase로_보낸다() {
        UUID memberId = UUID.randomUUID();
        server.expect(requestTo(BASE_URL + "/greetings"))
            .andExpect(method(HttpMethod.POST))
            .andExpect(header(HEADER_NAME, HEADER_VALUE))
            .andExpect(jsonPath("$.memberId").value(memberId.toString()))
            .andExpect(jsonPath("$.personaId").value(PERSONA_ID))
            .andExpect(jsonPath("$.nickname").value("소연"))
            .andExpect(jsonPath("$.characterName").value("티큐"))
            // 서버 Jackson 시간대 설정과 무관하게 UTC Z 문자열이어야 한다
            .andExpect(jsonPath("$.lastGreetedAt").value("2026-10-20T15:00:00Z"))
            .andRespond(withSuccess("{\"message\":\"소연 님,\\n오늘 어땠어요?\",\"mood\":\"HAPPY\"}",
                MediaType.APPLICATION_JSON));

        String message = adapter.generate(request(memberId, LAST_GREETED_AT));

        assertThat(message).isEqualTo("소연 님,\n오늘 어땠어요?");
        server.verify();
    }

    @Test
    void 처음_인사면_lastGreetedAt_키를_null_값으로_보낸다() {
        server.expect(requestTo(BASE_URL + "/greetings"))
            .andExpect(jsonPath("$.lastGreetedAt").value(nullValue()))
            .andRespond(withSuccess("{\"message\":\"안녕\"}", MediaType.APPLICATION_JSON));

        assertThat(adapter.generate(request(UUID.randomUUID(), null))).isEqualTo("안녕");
        server.verify();
    }

    @Test
    void 서버_오류_응답이면_AI_서버_오류로_바꾼다() {
        server.expect(requestTo(BASE_URL + "/greetings")).andRespond(withServerError());

        assertInvalid();
    }

    @ParameterizedTest
    @ValueSource(strings = {"{}", "{\"message\":123}", "{\"message\":null}", "null"})
    void message가_없거나_문자열이_아니거나_본문이_비면_AI_서버_오류로_바꾼다(String responseBody) {
        server.expect(requestTo(BASE_URL + "/greetings"))
            .andRespond(withSuccess(responseBody, MediaType.APPLICATION_JSON));

        assertInvalid();
    }

    @Test
    void 응답_본문이_비어_있으면_AI_서버_오류로_바꾼다() {
        server.expect(requestTo(BASE_URL + "/greetings"))
            .andRespond(withSuccess("", MediaType.APPLICATION_JSON));

        assertInvalid();
    }

    private void assertInvalid() {
        assertThatThrownBy(() -> adapter.generate(request(UUID.randomUUID(), LAST_GREETED_AT)))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.AI_SERVER_UNAVAILABLE));
    }

    private GreetingRequest request(UUID memberId, Instant lastGreetedAt) {
        return new GreetingRequest(memberId, PERSONA_ID, "소연", "티큐", lastGreetedAt);
    }

}
