package kr.teeq.api.aicharacter.core.port;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import kr.teeq.api.onboarding.core.constant.OnboardingOption;
import kr.teeq.api.onboarding.core.constant.OnboardingQuestion;

// AI 서버에 온보딩 답변으로 캐릭터 결정을 요청하는 port
public interface AiCharacterGenerationPort {

    GeneratedAiCharacter generate(UUID memberId, String characterName,
        Map<OnboardingQuestion, List<OnboardingOption>> answers);

}
