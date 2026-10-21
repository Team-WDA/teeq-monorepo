package kr.co.teeq.api.call.infrastructure.adapter;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import kr.co.teeq.api.call.core.port.AiCallSession;
import kr.co.teeq.api.call.core.port.AiCallSessionPort;
import kr.co.teeq.api.call.core.port.AiCallSessionRequest;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.common.infrastructure.properties.AiServerProperties;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Slf4j
@Component
public class AiServerCallSessionAdapter implements AiCallSessionPort {

    private static final String CALL_SESSION_ID_FIELD = "callSessionId";
    private static final String PERSONA_ID_FIELD = "personaId";
    private static final String PROMPT_VERSION_FIELD = "promptVersion";
    private static final String LLM_MODEL_FIELD = "llmModel";

    private final RestClient restClient;
    private final AiServerProperties properties;

    public AiServerCallSessionAdapter(
        @Qualifier("callRestClient") RestClient callRestClient,
        AiServerProperties properties
    ) {
        this.restClient = callRestClient;
        this.properties = properties;
    }

    // 재시도하지 않는다(세션 생성은 멱등이 아니다). 실패 원인은 cause로만 남기고 앱에는 노출하지 않는다
    @Override
    public AiCallSession createSession(AiCallSessionRequest request) {
        Map<String, Object> responseBody;
        try {
            responseBody = restClient.post()
                    .uri("/calls")
                    .header(properties.authHeaderName(), properties.authHeaderValue())
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(toRequestBody(request))
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

        if (responseBody.get(PERSONA_ID_FIELD) instanceof String responsePersonaId
                && !responsePersonaId.equals(request.personaId())) {
            log.warn("AI 서버 통화 세션 응답의 {}가 요청과 다릅니다", PERSONA_ID_FIELD);
        }

        // 앱에는 접속에 필요한 나머지 필드만 내려준다
        Map<String, Object> connection = new LinkedHashMap<>(responseBody);
        connection.remove(CALL_SESSION_ID_FIELD);
        connection.remove(PERSONA_ID_FIELD);
        connection.remove(PROMPT_VERSION_FIELD);
        connection.remove(LLM_MODEL_FIELD);
        return new AiCallSession(sessionId, readOptionalText(responseBody, PROMPT_VERSION_FIELD),
                readOptionalText(responseBody, LLM_MODEL_FIELD), Collections.unmodifiableMap(connection));
    }

    private Map<String, Object> toRequestBody(AiCallSessionRequest request) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("memberId", request.memberId().toString());
        body.put(PERSONA_ID_FIELD, request.personaId());
        body.put("nickname", request.nickname());
        body.put("characterName", request.characterName());
        body.put("maxDurationSeconds", request.maxDurationSeconds());
        body.put("limitKind", request.limitKind().name());
        return body;
    }

    // 통화 기록용 부가 정보라 없거나 비어 있어도 통화는 진행하고 null로 둔다
    private String readOptionalText(Map<String, Object> responseBody, String field) {
        if (responseBody.get(field) instanceof String text && !text.isBlank()) {
            return text;
        }
        log.warn("AI 서버 통화 세션 응답에 {}가 없거나 비어 있습니다", field);
        return null;
    }

}
