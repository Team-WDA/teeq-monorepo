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
import kr.co.teeq.api.call.core.constant.LimitKind;
import kr.co.teeq.api.call.core.port.AiCallSession;
import kr.co.teeq.api.call.core.port.AiCallSessionRequest;
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

    private final UUID memberId = UUID.randomUUID();

    private MockRestServiceServer server;
    private AiServerCallSessionAdapter adapter;

    @BeforeEach
    void setUp() {
        RestClient.Builder builder = RestClient.builder().baseUrl(BASE_URL);
        server = MockRestServiceServer.bindTo(builder).build();
        AiServerProperties properties = new AiServerProperties(BASE_URL, HEADER_NAME, HEADER_VALUE);
        adapter = new AiServerCallSessionAdapter(builder.build(), properties);
    }

    private AiCallSessionRequest request() {
        return new AiCallSessionRequest(memberId, "persona-1", "하늘", "다온", 600L, LimitKind.PER_DAY);
    }

    @Test
    void 정상_응답이면_세션_식별자와_실행_정보와_나머지_필드를_돌려준다() {
        server.expect(requestTo(BASE_URL + "/calls"))
                .andExpect(method(HttpMethod.POST))
                .andExpect(header(HEADER_NAME, HEADER_VALUE))
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.memberId").value(memberId.toString()))
                .andExpect(jsonPath("$.personaId").value("persona-1"))
                .andExpect(jsonPath("$.nickname").value("하늘"))
                .andExpect(jsonPath("$.characterName").value("다온"))
                .andExpect(jsonPath("$.maxDurationSeconds").value(600))
                .andExpect(jsonPath("$.limitKind").value("PER_DAY"))
                .andRespond(withSuccess(
                        "{\"callSessionId\":\"s-1\",\"personaId\":\"persona-1\",\"promptVersion\":\"v1\","
                                + "\"llmModel\":\"m-1\",\"livekitUrl\":\"u\",\"livekitToken\":\"t\"}",
                        MediaType.APPLICATION_JSON));

        AiCallSession session = adapter.createSession(request());

        assertThat(session.callSessionId()).isEqualTo("s-1");
        assertThat(session.promptVersion()).isEqualTo("v1");
        assertThat(session.llmModel()).isEqualTo("m-1");
        assertThat(session.connection()).isEqualTo(Map.of("livekitUrl", "u", "livekitToken", "t"));
        server.verify();
    }

    @Test
    void 응답_personaId가_요청과_달라도_통화는_진행한다() {
        server.expect(requestTo(BASE_URL + "/calls"))
                .andRespond(withSuccess("{\"callSessionId\":\"s-1\",\"personaId\":\"persona-other\"}",
                        MediaType.APPLICATION_JSON));

        AiCallSession session = adapter.createSession(request());

        assertThat(session.callSessionId()).isEqualTo("s-1");
        assertThat(session.connection()).isEmpty();
    }

    @Test
    void 프롬프트_버전과_모델이_누락되거나_공백이면_null로_둔다() {
        server.expect(requestTo(BASE_URL + "/calls"))
                .andRespond(withSuccess("{\"callSessionId\":\"s-1\",\"promptVersion\":\" \"}",
                        MediaType.APPLICATION_JSON));

        AiCallSession session = adapter.createSession(request());

        assertThat(session.promptVersion()).isNull();
        assertThat(session.llmModel()).isNull();
    }

    @Test
    void 나머지_필드에_null_값이_있어도_예외_없이_그대로_담는다() {
        server.expect(requestTo(BASE_URL + "/calls"))
                .andRespond(withSuccess("{\"callSessionId\":\"s-1\",\"region\":null}",
                        MediaType.APPLICATION_JSON));

        AiCallSession session = adapter.createSession(request());

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
                .andRespond(withSuccess("{\"livekitUrl\":\"u\"}", MediaType.APPLICATION_JSON));

        assertUnavailable();
    }

    @Test
    void 세션_식별자가_빈_문자열이면_AI_SERVER_UNAVAILABLE() {
        server.expect(requestTo(BASE_URL + "/calls"))
                .andRespond(withSuccess("{\"callSessionId\":\"\"}", MediaType.APPLICATION_JSON));

        assertUnavailable();
    }

    @Test
    void 본문이_비어_있으면_AI_SERVER_UNAVAILABLE() {
        server.expect(requestTo(BASE_URL + "/calls")).andRespond(withSuccess());

        assertUnavailable();
    }

    private void assertUnavailable() {
        assertThatThrownBy(() -> adapter.createSession(request()))
                .isInstanceOf(CustomException.class)
                .extracting(exception -> ((CustomException) exception).getErrorCode())
                .isEqualTo(ErrorCode.AI_SERVER_UNAVAILABLE);
    }

}
