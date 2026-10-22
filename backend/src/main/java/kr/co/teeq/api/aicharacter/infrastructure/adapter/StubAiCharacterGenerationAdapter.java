package kr.co.teeq.api.aicharacter.infrastructure.adapter;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import kr.co.teeq.api.aicharacter.core.port.AiCharacterGenerationPort;
import kr.co.teeq.api.aicharacter.core.port.GeneratedAiCharacter;
import kr.co.teeq.api.common.core.constant.CharacterType;
import kr.co.teeq.api.onboarding.core.constant.OnboardingOption;
import kr.co.teeq.api.onboarding.core.constant.OnboardingQuestion;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * AI 서버가 캐릭터 결정 API를 제공하기 전까지만 쓰는 임시 구현. AI 서버를 호출하지 않고 온보딩 답변과 무관하게
 * 항상 같은 캐릭터를 돌려준다. 가입부터 홈까지의 흐름을 테스트하기 위한 것이며, AI 서버가 완성되면 삭제한다.
 */
@Slf4j
@Component
@ConditionalOnProperty(prefix = "ai-server", name = "stub-character-enabled", havingValue = "true")
public class StubAiCharacterGenerationAdapter implements AiCharacterGenerationPort {

    private static final String PERSONA_ID = "stub-persona";
    private static final CharacterType CHARACTER_TYPE = CharacterType.CHARACTER_1;
    private static final List<String> PERSONALITY_TAGS = List.of("다정한", "차분한", "호기심 많은");

    public StubAiCharacterGenerationAdapter() {
        log.warn("ai-server.stub-character-enabled=true: AI 서버를 호출하지 않고 고정 캐릭터를 반환합니다."
            + " 내부 테스트 전용이므로 AI 서버가 준비되면 끄세요");
    }

    @Override
    public GeneratedAiCharacter generate(UUID memberId, Map<OnboardingQuestion, List<OnboardingOption>> answers) {
        return new GeneratedAiCharacter(PERSONA_ID, CHARACTER_TYPE, PERSONALITY_TAGS);
    }

}
