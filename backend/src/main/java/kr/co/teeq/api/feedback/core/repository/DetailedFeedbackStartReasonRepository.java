package kr.co.teeq.api.feedback.core.repository;

import java.util.UUID;
import kr.co.teeq.api.feedback.core.entity.DetailedFeedbackStartReason;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DetailedFeedbackStartReasonRepository extends JpaRepository<DetailedFeedbackStartReason, UUID> {

}
