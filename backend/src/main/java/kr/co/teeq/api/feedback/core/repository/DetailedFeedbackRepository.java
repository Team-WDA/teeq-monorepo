package kr.co.teeq.api.feedback.core.repository;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.feedback.core.entity.DetailedFeedback;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DetailedFeedbackRepository extends JpaRepository<DetailedFeedback, UUID> {

    boolean existsByCallHistoryIdAndDeletedFalse(UUID callHistoryId);

    // 회원의 통화 기록에 달린 활성(deleted = false) 상세 피드백(회원 삭제용)
    List<DetailedFeedback> findByCallHistoryMemberIdAndDeletedFalse(UUID memberId);

    // 생성 시각이 [createdAtFrom, createdAtTo)인 활성(deleted = false) 상세 피드백 수(관리자 홈)
    long countByCreatedAtGreaterThanEqualAndCreatedAtLessThanAndDeletedFalse(Instant createdAtFrom,
        Instant createdAtTo);

    // 생성 시각 내림차순 최근 활성(deleted = false) 상세 피드백 5건(관리자 홈)
    List<DetailedFeedback> findTop5ByDeletedFalseOrderByCreatedAtDesc();

}
