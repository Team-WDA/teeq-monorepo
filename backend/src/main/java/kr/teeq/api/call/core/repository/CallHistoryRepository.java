package kr.teeq.api.call.core.repository;

import jakarta.persistence.LockModeType;
import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kr.teeq.api.call.core.constant.CallStatus;
import kr.teeq.api.call.core.entity.CallHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface CallHistoryRepository extends JpaRepository<CallHistory, UUID> {

    Optional<CallHistory> findByIdAndDeletedFalse(UUID id);

    // 잠금 없이 통화 세션으로 조회한다(읽기 전용 조회용)
    Optional<CallHistory> findByCallSessionIdAndDeletedFalse(String callSessionId);

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
        where c.memberId = :memberId
          and c.deleted = false
          and c.startedAt >= :fromInclusive
          and c.startedAt < :toExclusive
        """)
    long sumDurationSeconds(@Param("memberId") UUID memberId,
        @Param("fromInclusive") Instant fromInclusive,
        @Param("toExclusive") Instant toExclusive);

}
