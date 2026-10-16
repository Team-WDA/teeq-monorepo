package kr.teeq.api.feedback.core.repository;

import java.util.UUID;
import kr.teeq.api.feedback.core.entity.RequiredFeedback;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RequiredFeedbackRepository extends JpaRepository<RequiredFeedback, UUID> {

    boolean existsByCallHistoryIdAndDeletedFalse(UUID callHistoryId);

}
