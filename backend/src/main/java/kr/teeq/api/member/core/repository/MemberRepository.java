package kr.teeq.api.member.core.repository;

import java.util.Optional;
import java.util.UUID;
import kr.teeq.api.member.core.entity.Member;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MemberRepository extends JpaRepository<Member, UUID> {

    Optional<Member> findByIdAndDeletedFalse(UUID id);

    Optional<Member> findByEmailAndDeletedFalse(String email);

    boolean existsByEmailAndDeletedFalse(String email);

    Optional<Member> findByNicknameIgnoreCaseAndDeletedFalse(String nickname);

}
