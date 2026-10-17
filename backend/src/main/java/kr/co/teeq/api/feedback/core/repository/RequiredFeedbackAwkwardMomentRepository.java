package kr.co.teeq.api.feedback.core.repository;

import java.util.UUID;
import kr.co.teeq.api.feedback.core.entity.RequiredFeedbackAwkwardMoment;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RequiredFeedbackAwkwardMomentRepository extends JpaRepository<RequiredFeedbackAwkwardMoment, UUID> {

}
