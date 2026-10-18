package kr.co.teeq.api.aicharacter.infrastructure.adapter;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import kr.co.teeq.api.aicharacter.core.constant.AiCharacterValidation;
import kr.co.teeq.api.aicharacter.core.port.AiCharacterGenerationPort;
import kr.co.teeq.api.aicharacter.core.port.GeneratedAiCharacter;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.common.infrastructure.properties.AiServerProperties;
import kr.co.teeq.api.onboarding.core.constant.OnboardingOption;
import kr.co.teeq.api.onboarding.core.constant.OnboardingQuestion;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Slf4j
@Component
public class AiServerCharacterGenerationAdapter implements AiCharacterGenerationPort {

    private static final String CHARACTER_NUMBER_FIELD = "character_number";
    private static final String PERSONALITY_TAGS_FIELD = "personality_tags";

    private final RestClient restClient;
    private final AiServerProperties properties;

    public AiServerCharacterGenerationAdapter(RestClient aiServerRestClient, AiServerProperties properties) {
        this.restClient = aiServerRestClient;
        this.properties = properties;
    }

    // 재시도하지 않는다. 실패 원인은 cause로만 남기고 앱에는 노출하지 않는다
    @Override
    public GeneratedAiCharacter generate(UUID memberId, Map<OnboardingQuestion, List<OnboardingOption>> answers) {
        Map<String, Object> responseBody;
        try {
            responseBody = restClient.post()
                .uri("/characters")
                .header(properties.authHeaderName(), properties.authHeaderValue())
                .contentType(MediaType.APPLICATION_JSON)
                .body(toRequestBody(memberId, answers))
                .retrieve()
                .body(new ParameterizedTypeReference<Map<String, Object>>() {
                });
        } catch (RestClientException exception) {
            throw new CustomException(ErrorCode.AI_SERVER_UNAVAILABLE, exception);
        }
        return toGeneratedAiCharacter(responseBody);
    }

    private Map<String, Object> toRequestBody(UUID memberId,
        Map<OnboardingQuestion, List<OnboardingOption>> answers) {
        List<Map<String, Object>> answerBodies = new ArrayList<>();
        answers.forEach((question, options) -> answerBodies.add(Map.of(
            "question_code", question.name(),
            "option_codes", options.stream().map(OnboardingOption::name).toList())));
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("user_id", memberId.toString());
        body.put("answers", answerBodies);
        return body;
    }

    // 계약에 맞지 않는 응답은 DB에 넣기 전에 502로 막는다(타입, 개수, 길이, 공백)
    private GeneratedAiCharacter toGeneratedAiCharacter(Map<String, Object> responseBody) {
        if (responseBody == null) {
            throw invalidResponse("응답 본문이 비어 있습니다");
        }
        if (!(responseBody.get(CHARACTER_NUMBER_FIELD) instanceof Integer characterNumber) || characterNumber < 0) {
            throw invalidResponse(CHARACTER_NUMBER_FIELD + "가 없거나 0 이상의 정수가 아닙니다");
        }
        if (!(responseBody.get(PERSONALITY_TAGS_FIELD) instanceof List<?> rawTags)
            || rawTags.size() != AiCharacterValidation.PERSONALITY_TAG_COUNT) {
            throw invalidResponse(PERSONALITY_TAGS_FIELD + "가 없거나 " + AiCharacterValidation.PERSONALITY_TAG_COUNT
                + "개가 아닙니다");
        }
        List<String> tags = new ArrayList<>();
        for (Object rawTag : rawTags) {
            // 제어 문자(\u0000 등)는 PostgreSQL이 저장을 거부해 500이 되므로 여기서 502로 막는다
            if (!(rawTag instanceof String tag) || tag.isBlank()
                || tag.length() > AiCharacterValidation.PERSONALITY_TAG_MAX_LENGTH
                || tag.chars().anyMatch(Character::isISOControl)) {
                throw invalidResponse(PERSONALITY_TAGS_FIELD + "에 문자열이 아니거나 비었거나 너무 길거나 제어 문자가 있는 값이 있습니다");
            }
            tags.add(tag);
        }
        return new GeneratedAiCharacter(characterNumber, List.copyOf(tags));
    }

    private CustomException invalidResponse(String reason) {
        log.error("AI 서버 캐릭터 응답이 계약에 맞지 않습니다: {}", reason);
        return new CustomException(ErrorCode.AI_SERVER_UNAVAILABLE);
    }

}
