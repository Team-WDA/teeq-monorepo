package kr.co.teeq.api.feedback.core.repository;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.feedback.core.entity.RequiredFeedback;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RequiredFeedbackRepository extends JpaRepository<RequiredFeedback, UUID> {

    boolean existsByCallHistoryIdAndDeletedFalse(UUID callHistoryId);

    // 생성 시각이 [createdAtFrom, createdAtTo)인 활성(deleted = false) 필수 피드백 수(관리자 홈)
    long countByCreatedAtGreaterThanEqualAndCreatedAtLessThanAndDeletedFalse(Instant createdAtFrom,
        Instant createdAtTo);

    // 생성 시각 내림차순 최근 활성(deleted = false) 필수 피드백 5건(관리자 홈)
    List<RequiredFeedback> findTop5ByDeletedFalseOrderByCreatedAtDesc();

}
