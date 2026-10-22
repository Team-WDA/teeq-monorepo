package kr.co.teeq.api.feedback.core.repository;

import java.util.Collection;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.feedback.core.entity.DetailedFeedback;
import kr.co.teeq.api.feedback.core.entity.DetailedFeedbackStartReason;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DetailedFeedbackStartReasonRepository extends JpaRepository<DetailedFeedbackStartReason, UUID> {

    // 상세 피드백들의 활성(deleted = false) 시작 이유(회원 삭제용)
    List<DetailedFeedbackStartReason> findByDetailedFeedbackInAndDeletedFalse(
        Collection<DetailedFeedback> detailedFeedbacks);

}
