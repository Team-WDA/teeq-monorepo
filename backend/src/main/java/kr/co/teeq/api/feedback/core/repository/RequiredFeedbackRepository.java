package kr.co.teeq.api.feedback.core.repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.feedback.core.entity.RequiredFeedback;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

public interface RequiredFeedbackRepository
    extends JpaRepository<RequiredFeedback, UUID>, JpaSpecificationExecutor<RequiredFeedback> {

    // 관리자 피드백 목록. 행마다 통화와 회원을 따로 조회하지 않도록 함께 가져온다(count 쿼리에는 적용되지 않는다)
    @Override
    @EntityGraph(attributePaths = {"callHistory", "callHistory.member"})
    Page<RequiredFeedback> findAll(Specification<RequiredFeedback> specification, Pageable pageable);

    // 통화 세션의 활성(deleted = false) 필수 피드백(관리자 통화 상세)
    Optional<RequiredFeedback> findByCallHistoryCallSessionIdAndDeletedFalse(String callSessionId);

    boolean existsByCallHistoryIdAndDeletedFalse(UUID callHistoryId);

    // 회원의 통화 기록에 달린 활성(deleted = false) 필수 피드백(회원 삭제용)
    List<RequiredFeedback> findByCallHistoryMemberIdAndDeletedFalse(UUID memberId);

    // 생성 시각이 [createdAtFrom, createdAtTo)인 활성(deleted = false) 필수 피드백 수(관리자 홈)
    long countByCreatedAtGreaterThanEqualAndCreatedAtLessThanAndDeletedFalse(Instant createdAtFrom,
        Instant createdAtTo);

    // 생성 시각 내림차순 최근 활성(deleted = false) 필수 피드백 5건(관리자 홈)
    List<RequiredFeedback> findTop5ByDeletedFalseOrderByCreatedAtDesc();

}
