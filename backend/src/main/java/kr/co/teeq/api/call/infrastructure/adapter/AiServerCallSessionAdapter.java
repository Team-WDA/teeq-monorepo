package kr.co.teeq.api.call.infrastructure.adapter;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import kr.co.teeq.api.call.core.port.AiCallSession;
import kr.co.teeq.api.call.core.port.AiCallSessionPort;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.common.infrastructure.properties.AiServerProperties;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Slf4j
@Component
public class AiServerCallSessionAdapter implements AiCallSessionPort {

    private static final String CALL_SESSION_ID_FIELD = "call_session_id";

    private final RestClient restClient;
    private final AiServerProperties properties;

    public AiServerCallSessionAdapter(RestClient aiServerRestClient, AiServerProperties properties) {
        this.restClient = aiServerRestClient;
        this.properties = properties;
    }

    // 재시도하지 않는다(세션 생성은 멱등이 아니다). 실패 원인은 cause로만 남기고 앱에는 노출하지 않는다
    @Override
    public AiCallSession createSession(UUID memberId, long maxDurationSeconds) {
        Map<String, Object> responseBody;
        try {
            responseBody = restClient.post()
                    .uri("/calls")
                    .header(properties.authHeaderName(), properties.authHeaderValue())
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(Map.of("user_id", memberId.toString(), "max_duration_seconds", maxDurationSeconds))
                    .retrieve()
                    .body(new ParameterizedTypeReference<Map<String, Object>>() {
                    });
        } catch (RestClientException exception) {
            throw new CustomException(ErrorCode.AI_SERVER_UNAVAILABLE, exception);
        }

        if (responseBody == null) {
            log.error("AI 서버 통화 세션 응답 본문이 비어 있습니다");
            throw new CustomException(ErrorCode.AI_SERVER_UNAVAILABLE);
        }
        Object callSessionId = responseBody.get(CALL_SESSION_ID_FIELD);
        if (!(callSessionId instanceof String sessionId) || sessionId.isBlank()) {
            log.error("AI 서버 통화 세션 응답에 {}가 없거나 비어 있습니다", CALL_SESSION_ID_FIELD);
            throw new CustomException(ErrorCode.AI_SERVER_UNAVAILABLE);
        }

        Map<String, Object> connection = new LinkedHashMap<>(responseBody);
        connection.remove(CALL_SESSION_ID_FIELD);
        return new AiCallSession(sessionId, Collections.unmodifiableMap(connection));
    }

}
