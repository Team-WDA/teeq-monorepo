package kr.co.teeq.api.call.core.repository;

import jakarta.persistence.LockModeType;
import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.call.core.constant.CallStatus;
import kr.co.teeq.api.call.core.entity.CallHistory;
import org.springframework.data.domain.Limit;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface CallHistoryRepository extends JpaRepository<CallHistory, UUID>,
    JpaSpecificationExecutor<CallHistory> {

    // 목록에서 회원을 함께 조회한다(회원 N+1 방지)
    @Override
    @EntityGraph(attributePaths = "member")
    Page<CallHistory> findAll(Specification<CallHistory> specification, Pageable pageable);

    Optional<CallHistory> findByIdAndDeletedFalse(UUID id);

    // 회원의 활성(deleted = false) 통화 기록 전체(회원 삭제용)
    List<CallHistory> findByMemberIdAndDeletedFalse(UUID memberId);

    // 회원에게 해당 상태이면서 시작 시각이 startedAtCutoff보다 늦은 활성 기록이 있는지(회원 삭제 시 진행 중 통화 확인용)
    boolean existsByMemberIdAndStatusInAndStartedAtGreaterThanAndDeletedFalse(
        UUID memberId, Collection<CallStatus> statuses, Instant startedAtCutoff);

    // 잠금 없이 통화 세션으로 조회한다(읽기 전용 조회용)
    Optional<CallHistory> findByCallSessionIdAndDeletedFalse(String callSessionId);

    // 회원의 활성 기록 중 피드백 대상(만료, 또는 통화 시간이 1초 이상인 종료)이면서 시작 시각이 가장 늦은 기록
    // (홈의 대기 피드백 조회용). 첫 건 한정은 limit으로 한다. 판정 규칙은 CallHistory.isFeedbackable과 같다
    @Query("""
        select c
        from CallHistory c
        where c.member.id = :memberId
          and c.deleted = false
          and (c.status = :expiredStatus or (c.status = :endedStatus and c.durationSeconds > 0))
        order by c.startedAt desc
        """)
    Optional<CallHistory> findLatestFeedbackableCall(@Param("memberId") UUID memberId,
        @Param("endedStatus") CallStatus endedStatus, @Param("expiredStatus") CallStatus expiredStatus, Limit limit);

    // 회원의 활성 기록 중 statuses에 없고 시작 시각이 startedAt 이하인 건수(통화 순번 계산용)
    long countByMemberIdAndStatusNotInAndStartedAtLessThanEqualAndDeletedFalse(
        UUID memberId, Collection<CallStatus> statuses, Instant startedAt);

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

    // 기간별(unit: day, month) 사용량. allMembers가 true면 전체 회원, false면 memberId 회원만 집계한다.
    // 시작 시각이 [fromInclusive, toExclusive)인 활성 기록만 집계하며 통화 횟수에서는 실패·대기 중·취소 기록을 제외한다.
    // 타입 없는 null은 PostgreSQL에서 bytea로 바인딩돼 실패하므로 memberId는 항상 non-null로 넘긴다
    @Query(value = """
        select to_char(date_trunc(:unit, started_at at time zone :zoneName), 'YYYY-MM-DD') as "periodStart",
               coalesce(sum(duration_seconds), 0) as "usedSeconds",
               count(*) filter (where status not in ('FAILED', 'PENDING', 'CANCELLED')) as "callCount"
        from call_history
        where deleted = false
          and (:allMembers = true or member_id = :memberId)
          and started_at >= :fromInclusive
          and started_at < :toExclusive
        group by 1
        order by 1
        """, nativeQuery = true)
    List<CallUsageRow> aggregateUsage(@Param("allMembers") boolean allMembers, @Param("memberId") UUID memberId,
        @Param("unit") String unit, @Param("zoneName") String zoneName,
        @Param("fromInclusive") Instant fromInclusive, @Param("toExclusive") Instant toExclusive);

    // 기간별 비정상 종료 집계 결과. 별칭은 getter 이름과 같아야 한다
    interface AbnormalCallRow {

        // KST 기준 기간 시작 날짜(yyyy-MM-dd)
        String getPeriodStart();

        long getAbnormalCount();

    }

    // 기간별(unit: day, month) 비정상 통화 건수. 시작 시각이 [fromInclusive, toExclusive)인 활성 기록만 집계한다.
    // 비정상 기준은 AbnormalCallCriteria의 이름 목록으로 받는다(status, end_reason은 문자열로 저장된다).
    // 타입 없는 null은 PostgreSQL에서 bytea로 바인딩돼 실패하므로 기간 경계는 항상 non-null로 넘긴다
    @Query(value = """
        select to_char(date_trunc(:unit, started_at at time zone :zoneName), 'YYYY-MM-DD') as "periodStart",
               count(*) as "abnormalCount"
        from call_history
        where deleted = false
          and started_at >= :fromInclusive
          and started_at < :toExclusive
          and (status in (:abnormalStatuses)
               or (status = 'ENDED' and end_reason in (:abnormalEndReasons)))
        group by 1
        order by 1
        """, nativeQuery = true)
    List<AbnormalCallRow> aggregateAbnormal(@Param("unit") String unit, @Param("zoneName") String zoneName,
        @Param("fromInclusive") Instant fromInclusive, @Param("toExclusive") Instant toExclusive,
        @Param("abnormalStatuses") List<String> abnormalStatuses,
        @Param("abnormalEndReasons") List<String> abnormalEndReasons);

    // 시작 시각이 [fromInclusive, toExclusive)인 활성(deleted = false) 기록 중 실패·대기 중·취소가 아닌 통화가
    // minimumCalls회 이상인 서로 다른 회원 수(관리자 홈의 주간 재통화 회원)
    @Query(value = """
        select count(*)
        from (
            select member_id
            from call_history
            where deleted = false
              and status not in ('FAILED', 'PENDING', 'CANCELLED')
              and started_at >= :fromInclusive
              and started_at < :toExclusive
            group by member_id
            having count(*) >= :minimumCalls
        ) returning_member
        """, nativeQuery = true)
    long countReturningMembers(@Param("fromInclusive") Instant fromInclusive,
        @Param("toExclusive") Instant toExclusive, @Param("minimumCalls") long minimumCalls);

    // 회원 통화 요약 결과. 별칭은 getter 이름과 같아야 한다
    interface MemberCallSummaryRow {

        long getCallCount();

        long getUsedSeconds();

        // 통화가 없으면 null
        Instant getLastStartedAt();

        long getRecentCallCount();

    }

    // 회원의 활성 기록 중 excludedStatuses가 아닌 통화의 건수·사용 시간(초)·마지막 시작 시각과,
    // 시작 시각이 recentFromInclusive 이후인 최근 통화 건수
    @Query("""
        select count(c) as callCount,
               coalesce(sum(c.durationSeconds), 0L) as usedSeconds,
               max(c.startedAt) as lastStartedAt,
               coalesce(sum(case when c.startedAt >= :recentFromInclusive then 1L else 0L end), 0L) as recentCallCount
        from CallHistory c
        where c.member.id = :memberId
          and c.deleted = false
          and c.status not in :excludedStatuses
        """)
    MemberCallSummaryRow summarizeByMember(@Param("memberId") UUID memberId,
        @Param("excludedStatuses") Collection<CallStatus> excludedStatuses,
        @Param("recentFromInclusive") Instant recentFromInclusive);

}
