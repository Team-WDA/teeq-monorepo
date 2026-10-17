package kr.teeq.api.home.infrastructure.adapter;

import java.util.LinkedHashMap;
import java.util.Map;
import kr.teeq.api.common.core.exception.CustomException;
import kr.teeq.api.common.core.exception.ErrorCode;
import kr.teeq.api.common.infrastructure.properties.AiServerProperties;
import kr.teeq.api.home.core.port.GreetingGenerationPort;
import kr.teeq.api.home.core.port.GreetingRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Slf4j
@Component
public class AiServerGreetingGenerationAdapter implements GreetingGenerationPort {

    private static final String MESSAGE_FIELD = "message";

    private final RestClient restClient;
    private final AiServerProperties properties;

    public AiServerGreetingGenerationAdapter(@Qualifier("greetingRestClient") RestClient greetingRestClient,
        AiServerProperties properties) {
        this.restClient = greetingRestClient;
        this.properties = properties;
    }

    // 재시도하지 않는다. 실패 원인은 cause로만 남기고 앱에는 노출하지 않는다
    @Override
    public String generate(GreetingRequest request) {
        Map<String, Object> responseBody;
        try {
            responseBody = restClient.post()
                .uri("/greetings")
                .header(properties.authHeaderName(), properties.authHeaderValue())
                .contentType(MediaType.APPLICATION_JSON)
                .body(toRequestBody(request))
                .retrieve()
                .body(new ParameterizedTypeReference<Map<String, Object>>() {
                });
        } catch (RestClientException exception) {
            throw new CustomException(ErrorCode.AI_SERVER_UNAVAILABLE, exception);
        }
        // 문구의 길이·내용 검증은 서비스가 한다. 여기서는 문자열인지만 확인한다
        if (responseBody == null) {
            throw invalidResponse("응답 본문이 비어 있습니다");
        }
        if (!(responseBody.get(MESSAGE_FIELD) instanceof String message)) {
            throw invalidResponse(MESSAGE_FIELD + "가 없거나 문자열이 아닙니다");
        }
        return message;
    }

    private Map<String, Object> toRequestBody(GreetingRequest request) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("user_id", request.memberId().toString());
        body.put("nickname", request.nickname());
        body.put("character_name", request.characterName());
        body.put("character_number", request.characterNumber());
        body.put("personality_tags", request.personalityTags());
        body.put("speech_style", request.speechStyle());
        return body;
    }

    private CustomException invalidResponse(String reason) {
        log.error("AI 서버 인사말 응답이 계약에 맞지 않습니다: {}", reason);
        return new CustomException(ErrorCode.AI_SERVER_UNAVAILABLE);
    }

}
