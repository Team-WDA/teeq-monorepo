package kr.co.teeq.api.home.infrastructure.adapter;

import java.util.LinkedHashMap;
import java.util.Map;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.common.infrastructure.properties.AiServerProperties;
import kr.co.teeq.api.home.core.constant.CharacterMood;
import kr.co.teeq.api.home.core.port.GreetingGenerationPort;
import kr.co.teeq.api.home.core.port.GreetingRequest;
import kr.co.teeq.api.home.core.port.GreetingResult;
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
    private static final String MOOD_FIELD = "mood";
    private static final int MOOD_LOG_MAX_LENGTH = 32;

    private final RestClient restClient;
    private final AiServerProperties properties;

    public AiServerGreetingGenerationAdapter(@Qualifier("greetingRestClient") RestClient greetingRestClient,
        AiServerProperties properties) {
        this.restClient = greetingRestClient;
        this.properties = properties;
    }

    // 재시도하지 않는다. 실패 원인은 cause로만 남기고 앱에는 노출하지 않는다
    @Override
    public GreetingResult generate(GreetingRequest request) {
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
        return new GreetingResult(message, readMood(responseBody.get(MOOD_FIELD)));
    }

    // 없거나 문자열이 아니거나 계약 밖의 값(소문자 포함)이면 문구는 유지하고 WELCOME으로 대체한다
    private CharacterMood readMood(Object rawMood) {
        if (rawMood instanceof String moodName) {
            try {
                return CharacterMood.valueOf(moodName);
            } catch (IllegalArgumentException exception) {
                log.warn("AI 서버 인사말 응답의 mood가 계약 밖의 값이라 WELCOME으로 대체합니다. mood={}", describeMood(moodName));
                return CharacterMood.WELCOME;
            }
        }
        log.warn("AI 서버 인사말 응답의 mood가 없거나 문자열이 아니라 WELCOME으로 대체합니다. mood={}", describeMood(rawMood));
        return CharacterMood.WELCOME;
    }

    // AI가 만든 값이 로그 한 줄을 키우거나 줄바꿈으로 위조하지 못하도록 타입과 앞부분만 남긴다
    private String describeMood(Object rawMood) {
        if (rawMood == null) {
            return "null";
        }
        if (!(rawMood instanceof String moodName)) {
            return rawMood.getClass().getSimpleName();
        }
        String singleLine = moodName.replaceAll("\\p{Cntrl}", "?");
        if (singleLine.length() <= MOOD_LOG_MAX_LENGTH) {
            return singleLine;
        }
        return singleLine.substring(0, MOOD_LOG_MAX_LENGTH) + "...(" + moodName.length() + "자)";
    }

    // lastGreetedAt이 null이어도 키를 보내야 하므로 Map.of 대신 LinkedHashMap을 쓴다.
    // 시각은 Jackson 시간대 설정의 영향을 받지 않도록 Instant#toString()의 UTC Z 문자열로 직접 넣는다
    private Map<String, Object> toRequestBody(GreetingRequest request) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("memberId", request.memberId().toString());
        body.put("personaId", request.personaId());
        body.put("nickname", request.nickname());
        body.put("characterName", request.characterName());
        body.put("lastGreetedAt", request.lastGreetedAt() == null ? null : request.lastGreetedAt().toString());
        return body;
    }

    private CustomException invalidResponse(String reason) {
        log.error("AI 서버 인사말 응답이 계약에 맞지 않습니다: {}", reason);
        return new CustomException(ErrorCode.AI_SERVER_UNAVAILABLE);
    }

}
