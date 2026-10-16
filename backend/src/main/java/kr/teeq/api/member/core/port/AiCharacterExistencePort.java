package kr.teeq.api.member.core.port;

import java.util.UUID;

// 회원의 AI 캐릭터 보유 여부를 묻는 port. member가 aicharacter를 직접 참조하면 도메인 순환이 되어 계층 규칙 때문에 둔다
public interface AiCharacterExistencePort {

    boolean existsByMemberId(UUID memberId);

}
