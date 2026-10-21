package kr.co.teeq.api.aicharacter.core.port;

import java.util.List;
import kr.co.teeq.api.common.core.constant.CharacterType;

// AI 서버가 정해 준 persona와 캐릭터. 성향 태그는 항상 3개다
public record GeneratedAiCharacter(String personaId, CharacterType characterType, List<String> personalityTags) {

}
