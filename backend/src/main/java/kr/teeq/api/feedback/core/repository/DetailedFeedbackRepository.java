package kr.teeq.api.feedback.core.repository;

import java.util.UUID;
import kr.teeq.api.feedback.core.entity.DetailedFeedback;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DetailedFeedbackRepository extends JpaRepository<DetailedFeedback, UUID> {

    boolean existsByCallHistoryIdAndDeletedFalse(UUID callHistoryId);

}
