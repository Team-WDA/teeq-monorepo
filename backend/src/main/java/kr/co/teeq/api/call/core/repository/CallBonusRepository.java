package kr.co.teeq.api.call.core.repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.call.core.entity.CallBonus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface CallBonusRepository extends JpaRepository<CallBonus, UUID> {

    // 회원의 해당 날짜(KST)에 유효한(취소되지 않은) 추가 시간(초) 합계
    @Query("""
        select coalesce(sum(b.seconds), 0L)
        from CallBonus b
        where b.member.id = :memberId
          and b.bonusDate = :bonusDate
          and b.deleted = false
        """)
    long sumActiveSeconds(@Param("memberId") UUID memberId, @Param("bonusDate") LocalDate bonusDate);

    // 취소된 행을 포함한 회원의 전체 부여 내역(관리자 조회용)
    List<CallBonus> findByMemberIdOrderByCreatedAtDesc(UUID memberId);

    Optional<CallBonus> findByIdAndMemberIdAndDeletedFalse(UUID id, UUID memberId);

}
