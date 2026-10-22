package kr.co.teeq.api.aicharacter.core.repository;

import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.aicharacter.core.entity.AiCharacter;
import org.springframework.data.jpa.repository.JpaRepository;

// 회원 삭제 시 soft delete 한다. 삭제된 회원은 로그인할 수 없어 조회 경로가 없으므로 deleted 조건 없이 member_id로 조회한다
// (unique도 전체 행에 걸린다)
// 존재 여부는 이름이 있는 캐릭터만 존재로 본다. 이름이 없는 캐릭터는 아직 생성이 끝나지 않은 상태다
public interface AiCharacterRepository extends JpaRepository<AiCharacter, UUID> {

    Optional<AiCharacter> findByMemberId(UUID memberId);

    boolean existsByMemberIdAndNameIsNotNull(UUID memberId);

}
