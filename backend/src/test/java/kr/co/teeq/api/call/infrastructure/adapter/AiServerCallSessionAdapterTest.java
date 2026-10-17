package kr.co.teeq.api.call.infrastructure.adapter;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.content;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.header;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.jsonPath;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withException;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withServerError;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

import java.io.IOException;
import java.util.Map;
import java.util.UUID;
import kr.co.teeq.api.call.core.port.AiCallSession;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.common.infrastructure.properties.AiServerProperties;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

class AiServerCallSessionAdapterTest {

    private static final String BASE_URL = "http://ai-server.test";
    private static final String HEADER_NAME = "X-Teeq-Server-Key";
    private static final String HEADER_VALUE = "dummy-server-key";

    private MockRestServiceServer server;
    private AiServerCallSessionAdapter adapter;

    @BeforeEach
    void setUp() {
        RestClient.Builder builder = RestClient.builder().baseUrl(BASE_URL);
        server = MockRestServiceServer.bindTo(builder).build();
        AiServerProperties properties = new AiServerProperties(BASE_URL, HEADER_NAME, HEADER_VALUE, 5000);
        adapter = new AiServerCallSessionAdapter(builder.build(), properties);
    }

    @Test
    void 정상_응답이면_세션_식별자와_나머지_필드를_돌려준다() {
        UUID memberId = UUID.randomUUID();
        server.expect(requestTo(BASE_URL + "/calls"))
                .andExpect(method(HttpMethod.POST))
                .andExpect(header(HEADER_NAME, HEADER_VALUE))
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.user_id").value(memberId.toString()))
                .andExpect(jsonPath("$.max_duration_seconds").value(600))
                .andRespond(withSuccess(
                        "{\"call_session_id\":\"s-1\",\"livekit_url\":\"u\",\"livekit_token\":\"t\"}",
                        MediaType.APPLICATION_JSON));

        AiCallSession session = adapter.createSession(memberId, 600L);

        assertThat(session.callSessionId()).isEqualTo("s-1");
        assertThat(session.connection()).isEqualTo(Map.of("livekit_url", "u", "livekit_token", "t"));
        server.verify();
    }

    @Test
    void 나머지_필드에_null_값이_있어도_예외_없이_그대로_담는다() {
        server.expect(requestTo(BASE_URL + "/calls"))
                .andRespond(withSuccess("{\"call_session_id\":\"s-1\",\"region\":null}",
                        MediaType.APPLICATION_JSON));

        AiCallSession session = adapter.createSession(UUID.randomUUID(), 600L);

        assertThat(session.callSessionId()).isEqualTo("s-1");
        assertThat(session.connection()).containsOnlyKeys("region");
        assertThat(session.connection().get("region")).isNull();
    }

    @Test
    void 서버_오류_응답이면_AI_SERVER_UNAVAILABLE() {
        server.expect(requestTo(BASE_URL + "/calls")).andRespond(withServerError());

        assertUnavailable();
    }

    @Test
    void 연결_오류이면_AI_SERVER_UNAVAILABLE() {
        server.expect(requestTo(BASE_URL + "/calls")).andRespond(withException(new IOException("연결 실패")));

        assertUnavailable();
    }

    @Test
    void 세션_식별자가_없으면_AI_SERVER_UNAVAILABLE() {
        server.expect(requestTo(BASE_URL + "/calls"))
                .andRespond(withSuccess("{\"livekit_url\":\"u\"}", MediaType.APPLICATION_JSON));

        assertUnavailable();
    }

    @Test
    void 세션_식별자가_빈_문자열이면_AI_SERVER_UNAVAILABLE() {
        server.expect(requestTo(BASE_URL + "/calls"))
                .andRespond(withSuccess("{\"call_session_id\":\"\"}", MediaType.APPLICATION_JSON));

        assertUnavailable();
    }

    @Test
    void 본문이_비어_있으면_AI_SERVER_UNAVAILABLE() {
        server.expect(requestTo(BASE_URL + "/calls")).andRespond(withSuccess());

        assertUnavailable();
    }

    private void assertUnavailable() {
        assertThatThrownBy(() -> adapter.createSession(UUID.randomUUID(), 600L))
                .isInstanceOf(CustomException.class)
                .extracting(exception -> ((CustomException) exception).getErrorCode())
                .isEqualTo(ErrorCode.AI_SERVER_UNAVAILABLE);
    }

}
