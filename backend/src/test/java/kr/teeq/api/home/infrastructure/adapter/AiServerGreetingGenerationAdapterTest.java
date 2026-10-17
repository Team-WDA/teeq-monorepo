package kr.teeq.api.home.infrastructure.adapter;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.header;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.jsonPath;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withServerError;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

import java.util.List;
import java.util.UUID;
import kr.teeq.api.common.core.exception.CustomException;
import kr.teeq.api.common.core.exception.ErrorCode;
import kr.teeq.api.common.infrastructure.properties.AiServerProperties;
import kr.teeq.api.home.core.port.GreetingRequest;
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

    private MockRestServiceServer server;
    private AiServerGreetingGenerationAdapter adapter;

    @BeforeEach
    void setUp() {
        RestClient.Builder builder = RestClient.builder().baseUrl(BASE_URL);
        server = MockRestServiceServer.bindTo(builder).build();
        AiServerProperties properties = new AiServerProperties(BASE_URL, HEADER_NAME, HEADER_VALUE, 5000);
        adapter = new AiServerGreetingGenerationAdapter(builder.build(), properties);
    }

    @Test
    void 정상_응답이면_message를_돌려주고_요청_본문_필드를_보낸다() {
        UUID memberId = UUID.randomUUID();
        server.expect(requestTo(BASE_URL + "/greetings"))
            .andExpect(method(HttpMethod.POST))
            .andExpect(header(HEADER_NAME, HEADER_VALUE))
            .andExpect(jsonPath("$.user_id").value(memberId.toString()))
            .andExpect(jsonPath("$.nickname").value("소연"))
            .andExpect(jsonPath("$.character_name").value("티큐"))
            .andExpect(jsonPath("$.character_number").value(3))
            .andExpect(jsonPath("$.personality_tags[0]").value("다정한"))
            .andExpect(jsonPath("$.speech_style").value("SPEECH_STYLE_GENTLE_POLITE"))
            .andRespond(withSuccess("{\"message\":\"소연 님,\\n오늘 어땠어요?\"}", MediaType.APPLICATION_JSON));

        String message = adapter.generate(request(memberId));

        assertThat(message).isEqualTo("소연 님,\n오늘 어땠어요?");
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
        assertThatThrownBy(() -> adapter.generate(request(UUID.randomUUID())))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.AI_SERVER_UNAVAILABLE));
    }

    private GreetingRequest request(UUID memberId) {
        return new GreetingRequest(memberId, "소연", "티큐", 3, List.of("다정한", "차분한", "든든한"),
            "SPEECH_STYLE_GENTLE_POLITE");
    }

}
