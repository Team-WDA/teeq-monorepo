package kr.co.teeq.api.aicharacter.infrastructure.adapter;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import kr.co.teeq.api.aicharacter.core.constant.AiCharacterValidation;
import kr.co.teeq.api.aicharacter.core.port.AiCharacterGenerationPort;
import kr.co.teeq.api.aicharacter.core.port.GeneratedAiCharacter;
import kr.co.teeq.api.common.core.constant.CharacterType;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.common.infrastructure.properties.AiServerProperties;
import kr.co.teeq.api.onboarding.core.constant.OnboardingOption;
import kr.co.teeq.api.onboarding.core.constant.OnboardingQuestion;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Slf4j
@Component
// 임시 어댑터(StubAiCharacterGenerationAdapter)를 켜지 않은 기본 상태에서만 등록한다
@ConditionalOnProperty(prefix = "ai-server", name = "stub-character-enabled", havingValue = "false",
    matchIfMissing = true)
public class AiServerCharacterGenerationAdapter implements AiCharacterGenerationPort {

    private static final String PERSONA_ID_FIELD = "personaId";
    private static final String CHARACTER_TYPE_FIELD = "characterType";
    private static final String PERSONALITY_TAGS_FIELD = "personalityTags";

    // onboarding_submission.persona_id 컬럼 길이와 같다
    private static final int PERSONA_ID_MAX_LENGTH = 64;

    private final RestClient restClient;
    private final AiServerProperties properties;

    public AiServerCharacterGenerationAdapter(
        @Qualifier("characterRestClient") RestClient characterRestClient,
        AiServerProperties properties
    ) {
        this.restClient = characterRestClient;
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
            "questionCode", question.name(),
            "optionCodes", options.stream().map(OnboardingOption::name).toList())));
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("memberId", memberId.toString());
        body.put("answers", answerBodies);
        return body;
    }

    // 계약에 맞지 않는 응답은 DB에 넣기 전에 502로 막는다(타입, 개수, 길이, 공백)
    private GeneratedAiCharacter toGeneratedAiCharacter(Map<String, Object> responseBody) {
        if (responseBody == null) {
            throw invalidResponse("응답 본문이 비어 있습니다");
        }
        if (!(responseBody.get(PERSONA_ID_FIELD) instanceof String personaId) || personaId.isBlank()
            || personaId.length() > PERSONA_ID_MAX_LENGTH || personaId.chars().anyMatch(Character::isISOControl)) {
            throw invalidResponse(PERSONA_ID_FIELD + "가 없거나 비었거나 너무 길거나 제어 문자가 있습니다");
        }
        CharacterType characterType = parseCharacterType(responseBody.get(CHARACTER_TYPE_FIELD));
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
        return new GeneratedAiCharacter(personaId, characterType, List.copyOf(tags));
    }

    private CharacterType parseCharacterType(Object rawCharacterType) {
        if (rawCharacterType instanceof String name) {
            for (CharacterType characterType : CharacterType.values()) {
                if (characterType.name().equals(name)) {
                    return characterType;
                }
            }
        }
        throw invalidResponse(CHARACTER_TYPE_FIELD + "가 없거나 정해진 캐릭터 유형이 아닙니다");
    }

    private CustomException invalidResponse(String reason) {
        log.error("AI 서버 캐릭터 응답이 계약에 맞지 않습니다: {}", reason);
        return new CustomException(ErrorCode.AI_SERVER_UNAVAILABLE);
    }

}
