package kr.teeq.api.call.core.repository;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import kr.teeq.api.call.core.entity.CallHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface CallHistoryRepository extends JpaRepository<CallHistory, UUID> {

    Optional<CallHistory> findByCallSessionIdAndDeletedFalse(String callSessionId);

    // 통화 시작 시각이 [fromInclusive, toExclusive)인 활성 기록의 사용 시간(초) 합계
    @Query("""
        select coalesce(sum(c.durationSeconds), 0L)
        from CallHistory c
        where c.memberId = :memberId
          and c.deleted = false
          and c.startedAt >= :fromInclusive
          and c.startedAt < :toExclusive
        """)
    long sumDurationSeconds(@Param("memberId") UUID memberId,
        @Param("fromInclusive") Instant fromInclusive,
        @Param("toExclusive") Instant toExclusive);

}
