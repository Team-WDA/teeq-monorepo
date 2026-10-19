package kr.co.teeq.api.call.core.repository;

import jakarta.persistence.LockModeType;
import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.call.core.constant.CallStatus;
import kr.co.teeq.api.call.core.entity.CallHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface CallHistoryRepository extends JpaRepository<CallHistory, UUID> {

    Optional<CallHistory> findByIdAndDeletedFalse(UUID id);

    // 잠금 없이 통화 세션으로 조회한다(읽기 전용 조회용)
    Optional<CallHistory> findByCallSessionIdAndDeletedFalse(String callSessionId);

    // 회원의 활성 기록 중 해당 상태이면서 시작 시각이 가장 늦은 기록(홈의 대기 피드백 조회용)
    Optional<CallHistory> findFirstByMemberIdAndStatusInAndDeletedFalseOrderByStartedAtDesc(
        UUID memberId, Collection<CallStatus> statuses);

    // 회원의 활성 기록 중 status가 아니고 시작 시각이 startedAt 이하인 건수(통화 순번 계산용)
    long countByMemberIdAndStatusNotAndStartedAtLessThanEqualAndDeletedFalse(
        UUID memberId, CallStatus status, Instant startedAt);

    // 종료 보고의 동시 중복 처리를 직렬화하기 위해 행을 잠그고 조회한다
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    Optional<CallHistory> findWithLockByCallSessionIdAndDeletedFalse(String callSessionId);

    // 시작 시각이 startedAtCutoff 이하인(만료 대상 후보) 회원의 해당 상태 기록.
    // 종료 보고와의 lost update를 막기 위해 행을 잠그고 조회한다(대기 후 조건을 재평가해 이미 종료된 행은 빠진다)
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    List<CallHistory> findByMemberIdAndStatusInAndStartedAtLessThanEqualAndDeletedFalse(
        UUID memberId, Collection<CallStatus> statuses, Instant startedAtCutoff);

    // 통화 시작 시각이 [fromInclusive, toExclusive)인 활성 기록의 사용 시간(초) 합계
    @Query("""
        select coalesce(sum(c.durationSeconds), 0L)
        from CallHistory c
        where c.member.id = :memberId
          and c.deleted = false
          and c.startedAt >= :fromInclusive
          and c.startedAt < :toExclusive
        """)
    long sumDurationSeconds(@Param("memberId") UUID memberId,
        @Param("fromInclusive") Instant fromInclusive,
        @Param("toExclusive") Instant toExclusive);

    // 통화 시작 시각이 [fromInclusive, toExclusive)인 전체 회원 활성 기록의 사용 시간(초) 합계
    @Query("""
        select coalesce(sum(c.durationSeconds), 0L)
        from CallHistory c
        where c.deleted = false
          and c.startedAt >= :fromInclusive
          and c.startedAt < :toExclusive
        """)
    long sumDurationSecondsOfAllMembers(@Param("fromInclusive") Instant fromInclusive,
        @Param("toExclusive") Instant toExclusive);

    // 기간별 사용량 집계 결과. 별칭은 getter 이름과 같아야 한다
    interface CallUsageRow {

        // KST 기준 기간 시작 날짜(yyyy-MM-dd)
        String getPeriodStart();

        long getUsedSeconds();

        long getCallCount();

    }

    // 전체 회원의 기간별(unit: day, month) 사용량. 시작 시각이 [fromInclusive, toExclusive)인 활성 기록만 집계하며
    // 통화 횟수에서는 실패·대기 중 기록을 제외한다
    @Query(value = """
        select to_char(date_trunc(:unit, started_at at time zone :zoneName), 'YYYY-MM-DD') as "periodStart",
               coalesce(sum(duration_seconds), 0) as "usedSeconds",
               count(*) filter (where status not in ('FAILED', 'PENDING')) as "callCount"
        from call_history
        where deleted = false
          and started_at >= :fromInclusive
          and started_at < :toExclusive
        group by 1
        order by 1
        """, nativeQuery = true)
    List<CallUsageRow> aggregateUsageOfAllMembers(@Param("unit") String unit,
        @Param("zoneName") String zoneName, @Param("fromInclusive") Instant fromInclusive,
        @Param("toExclusive") Instant toExclusive);

    // 특정 회원의 기간별(unit: day, month) 사용량
    @Query(value = """
        select to_char(date_trunc(:unit, started_at at time zone :zoneName), 'YYYY-MM-DD') as "periodStart",
               coalesce(sum(duration_seconds), 0) as "usedSeconds",
               count(*) filter (where status not in ('FAILED', 'PENDING')) as "callCount"
        from call_history
        where deleted = false
          and member_id = :memberId
          and started_at >= :fromInclusive
          and started_at < :toExclusive
        group by 1
        order by 1
        """, nativeQuery = true)
    List<CallUsageRow> aggregateUsageOfMember(@Param("memberId") UUID memberId, @Param("unit") String unit,
        @Param("zoneName") String zoneName, @Param("fromInclusive") Instant fromInclusive,
        @Param("toExclusive") Instant toExclusive);

}
