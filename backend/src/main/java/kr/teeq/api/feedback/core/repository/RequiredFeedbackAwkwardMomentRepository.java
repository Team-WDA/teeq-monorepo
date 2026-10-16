package kr.teeq.api.feedback.core.repository;

import java.util.UUID;
import kr.teeq.api.feedback.core.entity.RequiredFeedbackAwkwardMoment;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RequiredFeedbackAwkwardMomentRepository extends JpaRepository<RequiredFeedbackAwkwardMoment, UUID> {

}
