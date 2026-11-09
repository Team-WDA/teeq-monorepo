package kr.co.teeq.api.call.infrastructure.adapter;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.header;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withServerError;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withStatus;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

import java.io.IOException;
import java.math.BigDecimal;
import java.util.Optional;
import kr.co.teeq.api.call.core.port.AiCallDetail;
import kr.co.teeq.api.call.core.port.AiCallResultStatus;
import kr.co.teeq.api.call.core.port.AiCallTurn;
import kr.co.teeq.api.call.core.port.AiCallTurnRole;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.common.infrastructure.properties.AiServerProperties;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

class AiServerCallDetailAdapterTest {

    private static final String BASE_URL = "http://ai-server.test";
    private static final String HEADER_NAME = "X-Teeq-Server-Key";
    private static final String HEADER_VALUE = "dummy-server-key";
    private static final String SESSION_ID = "sess-1";

    private MockRestServiceServer server;
    private AiServerCallDetailAdapter adapter;

    @BeforeEach
    void setUp() {
        RestClient.Builder builder = RestClient.builder().baseUrl(BASE_URL);
        server = MockRestServiceServer.bindTo(builder).build();
        AiServerProperties properties = new AiServerProperties(BASE_URL, HEADER_NAME, HEADER_VALUE);
        adapter = new AiServerCallDetailAdapter(builder.build(), properties);
    }

    @Test
    void 정상_응답이면_모든_필드와_turn_두_개를_매핑한다() {
        server.expect(requestTo(BASE_URL + "/calls/sess-1"))
            .andExpect(method(HttpMethod.GET))
            .andExpect(header(HEADER_NAME, HEADER_VALUE))
            .andRespond(withSuccess("""
                {"sessionId":"sess-1","summary":"요약","llmModel":"model-a","estimatedCostUsd":0.0123,
                 "memoryInjected":true,"turns":[
                  {"index":0,"role":"USER","text":"안녕","interrupted":false,
                   "endToEndLatencyMillis":900,"llmFirstTokenMillis":300},
                  {"index":1,"role":"ASSISTANT","text":"반가워","interrupted":true}
                 ]}
                """, MediaType.APPLICATION_JSON));

        AiCallDetail detail = adapter.find(SESSION_ID).orElseThrow();

        assertThat(detail.sessionId()).isEqualTo("sess-1");
        assertThat(detail.summary()).isEqualTo("요약");
        assertThat(detail.llmModel()).isEqualTo("model-a");
        assertThat(detail.estimatedCostUsd()).isEqualByComparingTo(new BigDecimal("0.0123"));
        assertThat(detail.memoryInjected()).isTrue();
        assertThat(detail.turns()).containsExactly(
            new AiCallTurn(0, AiCallTurnRole.USER, "안녕", false, 900, 300),
            new AiCallTurn(1, AiCallTurnRole.ASSISTANT, "반가워", true, null, null));
        server.verify();
    }

    @Test
    void 일부_필드가_없으면_null로_매핑하고_예외를_던지지_않는다() {
        server.expect(requestTo(BASE_URL + "/calls/sess-1"))
            .andRespond(withSuccess("{\"sessionId\":\"sess-1\",\"turns\":[]}", MediaType.APPLICATION_JSON));

        AiCallDetail detail = adapter.find(SESSION_ID).orElseThrow();

        assertThat(detail.summary()).isNull();
        assertThat(detail.llmModel()).isNull();
        assertThat(detail.estimatedCostUsd()).isNull();
        assertThat(detail.memoryInjected()).isNull();
    }

    @ParameterizedTest
    @ValueSource(strings = {
        "{\"sessionId\":\"sess-1\"}",
        "{\"sessionId\":\"sess-1\",\"turns\":null}",
        "{\"sessionId\":\"sess-1\",\"turns\":[]}"
    })
    void turns가_없거나_비어_있으면_빈_목록이다(String responseBody) {
        server.expect(requestTo(BASE_URL + "/calls/sess-1"))
            .andRespond(withSuccess(responseBody, MediaType.APPLICATION_JSON));

        assertThat(adapter.find(SESSION_ID).orElseThrow().turns()).isEmpty();
    }

    @ParameterizedTest
    @ValueSource(strings = {
        "{\"detail\":{\"code\":\"SESSION_NOT_FOUND\",\"message\":\"call session not found\"}}",
        "{\"code\":\"SESSION_NOT_FOUND\"}"
    })
    void SESSION_NOT_FOUND_404면_빈_값이다(String responseBody) {
        server.expect(requestTo(BASE_URL + "/calls/sess-1"))
            .andRespond(withStatus(HttpStatus.NOT_FOUND).contentType(MediaType.APPLICATION_JSON).body(responseBody));

        assertThat(adapter.find(SESSION_ID)).isEqualTo(Optional.empty());
    }

    @ParameterizedTest
    @ValueSource(strings = {
        "{\"detail\":\"Not Found\"}",
        "{\"detail\":{\"code\":\"OTHER\"}}",
        "",
        "not json"
    })
    void 그_외_404면_AI_서버_오류로_바꾼다(String responseBody) {
        server.expect(requestTo(BASE_URL + "/calls/sess-1"))
            .andRespond(withStatus(HttpStatus.NOT_FOUND).contentType(MediaType.APPLICATION_JSON).body(responseBody));

        assertUnavailable(SESSION_ID);
    }

    @ParameterizedTest
    @ValueSource(strings = {"RECEIVED", "PENDING", "MISSING"})
    void resultStatus를_파싱한다(String resultStatus) {
        server.expect(requestTo(BASE_URL + "/calls/sess-1")).andRespond(withSuccess(
            "{\"sessionId\":\"sess-1\",\"resultStatus\":\"" + resultStatus + "\",\"turns\":[]}",
            MediaType.APPLICATION_JSON));

        assertThat(adapter.find(SESSION_ID).orElseThrow().resultStatus())
            .isEqualTo(AiCallResultStatus.valueOf(resultStatus));
    }

    @ParameterizedTest
    @ValueSource(strings = {
        "{\"sessionId\":\"sess-1\",\"turns\":[]}",
        "{\"sessionId\":\"sess-1\",\"resultStatus\":\"WEIRD\",\"turns\":[]}",
        "{\"sessionId\":\"sess-1\",\"resultStatus\":1,\"turns\":[]}"
    })
    void resultStatus가_없거나_알_수_없으면_null이다(String responseBody) {
        server.expect(requestTo(BASE_URL + "/calls/sess-1"))
            .andRespond(withSuccess(responseBody, MediaType.APPLICATION_JSON));

        assertThat(adapter.find(SESSION_ID).orElseThrow().resultStatus()).isNull();
    }

    @Test
    void 서버_오류_응답이면_AI_서버_오류로_바꾼다() {
        server.expect(requestTo(BASE_URL + "/calls/sess-1")).andRespond(withServerError());

        assertUnavailable(SESSION_ID);
    }

    @Test
    void 연결에_실패하면_AI_서버_오류로_바꾼다() {
        server.expect(requestTo(BASE_URL + "/calls/sess-1")).andRespond(request -> {
            throw new IOException("connection refused");
        });

        assertUnavailable(SESSION_ID);
    }

    @ParameterizedTest
    @ValueSource(strings = {
        "{\"sessionId\":\"sess-1\",\"turns\":[{\"index\":0,\"role\":\"SYSTEM\",\"text\":\"x\"}]}",
        "{\"sessionId\":\"sess-1\",\"turns\":[{\"index\":0,\"role\":\"user\",\"text\":\"x\"}]}",
        "{\"sessionId\":\"sess-1\",\"turns\":[{\"index\":0,\"text\":\"x\"}]}",
        "{\"sessionId\":\"sess-1\",\"turns\":\"oops\"}",
        "{\"sessionId\":\"sess-1\",\"turns\":[\"oops\"]}",
        "null"
    })
    void 알_수_없는_role이거나_응답_형태가_이상하면_AI_서버_오류로_바꾼다(String responseBody) {
        server.expect(requestTo(BASE_URL + "/calls/sess-1"))
            .andRespond(withSuccess(responseBody, MediaType.APPLICATION_JSON));

        assertUnavailable(SESSION_ID);
    }

    @Test
    void 응답의_sessionId가_없으면_요청한_id를_사용한다() {
        server.expect(requestTo(BASE_URL + "/calls/sess-1"))
            .andRespond(withSuccess("{\"turns\":[]}", MediaType.APPLICATION_JSON));

        assertThat(adapter.find(SESSION_ID).orElseThrow().sessionId()).isEqualTo(SESSION_ID);
    }

    @Test
    void 응답의_sessionId가_요청과_다르면_AI_서버_오류로_바꾼다() {
        server.expect(requestTo(BASE_URL + "/calls/sess-1"))
            .andRespond(withSuccess("{\"sessionId\":\"other\",\"turns\":[]}", MediaType.APPLICATION_JSON));

        assertUnavailable(SESSION_ID);
    }

    @Test
    void sessionId의_슬래시와_공백은_한_경로_세그먼트로_인코딩한다() {
        server.expect(requestTo(BASE_URL + "/calls/a%2Fb%20c"))
            .andRespond(withSuccess("{\"turns\":[]}", MediaType.APPLICATION_JSON));

        assertThat(adapter.find("a/b c")).isPresent();
        server.verify();
    }

    private void assertUnavailable(String callSessionId) {
        assertThatThrownBy(() -> adapter.find(callSessionId))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.AI_SERVER_UNAVAILABLE));
    }

}
