package kr.co.teeq.api.aicharacter.core.port;

import java.util.List;

// AI 서버가 정해 준 캐릭터. 성향 태그는 항상 3개다
public record GeneratedAiCharacter(int characterNumber, List<String> personalityTags) {

}
