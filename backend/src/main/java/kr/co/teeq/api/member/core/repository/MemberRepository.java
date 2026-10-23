package kr.co.teeq.api.member.core.repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.member.core.entity.Member;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

public interface MemberRepository extends JpaRepository<Member, UUID>, JpaSpecificationExecutor<Member> {

    Optional<Member> findByIdAndDeletedFalse(UUID id);

    Optional<Member> findByFirebaseUidAndDeletedFalse(String firebaseUid);

    Optional<Member> findByNicknameIgnoreCaseAndDeletedFalse(String nickname);

    // 활성(deleted = false) 회원 수. 관리자 홈용
    long countByDeletedFalse();

    // 생성 시각이 createdAtFrom 이상인 활성(deleted = false) 회원 수(관리자 홈의 오늘 가입)
    long countByCreatedAtGreaterThanEqualAndDeletedFalse(Instant createdAtFrom);

    // 생성 시각 내림차순 최근 활성(deleted = false) 회원 5명(관리자 홈의 최근 가입)
    List<Member> findTop5ByDeletedFalseOrderByCreatedAtDesc();

}
