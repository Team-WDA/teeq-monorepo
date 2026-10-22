package kr.co.teeq.api.feedback.core.repository;

import java.util.Collection;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.feedback.core.entity.RequiredFeedback;
import kr.co.teeq.api.feedback.core.entity.RequiredFeedbackAwkwardMoment;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RequiredFeedbackAwkwardMomentRepository extends JpaRepository<RequiredFeedbackAwkwardMoment, UUID> {

    // 필수 피드백들의 활성(deleted = false) 어색했던 순간(회원 삭제용)
    List<RequiredFeedbackAwkwardMoment> findByRequiredFeedbackInAndDeletedFalse(
        Collection<RequiredFeedback> requiredFeedbacks);

}
