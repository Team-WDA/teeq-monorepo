package kr.co.teeq.api.feedback.application.handler;

import java.time.Clock;
import java.util.List;
import kr.co.teeq.api.feedback.core.entity.DetailedFeedback;
import kr.co.teeq.api.feedback.core.entity.DetailedFeedbackStartReason;
import kr.co.teeq.api.feedback.core.entity.RequiredFeedback;
import kr.co.teeq.api.feedback.core.entity.RequiredFeedbackAwkwardMoment;
import kr.co.teeq.api.feedback.core.repository.DetailedFeedbackRepository;
import kr.co.teeq.api.feedback.core.repository.DetailedFeedbackStartReasonRepository;
import kr.co.teeq.api.feedback.core.repository.RequiredFeedbackAwkwardMomentRepository;
import kr.co.teeq.api.feedback.core.repository.RequiredFeedbackRepository;
import kr.co.teeq.api.member.core.event.HandlesMemberDeletion;
import kr.co.teeq.api.member.core.event.MemberDeletedEvent;
import lombok.RequiredArgsConstructor;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/**
 * 회원 삭제 시 회원의 통화 기록에 달린 필수/상세 피드백과 그 하위 행(어색했던 순간, 시작 이유)을 soft delete 한다.
 * 통화 기록은 피드백이 참조하므로(feedback → call) 통화 쪽 핸들러가 아니라 이 핸들러가 정리한다.
 */
@Component
@RequiredArgsConstructor
@HandlesMemberDeletion(entities = {
    RequiredFeedback.class,
    DetailedFeedback.class,
    RequiredFeedbackAwkwardMoment.class,
    DetailedFeedbackStartReason.class
})
public class FeedbackMemberDeletionHandler {

    private final RequiredFeedbackRepository requiredFeedbackRepository;
    private final DetailedFeedbackRepository detailedFeedbackRepository;
    private final RequiredFeedbackAwkwardMomentRepository awkwardMomentRepository;
    private final DetailedFeedbackStartReasonRepository startReasonRepository;
    private final Clock clock;

    @EventListener
    public void handle(MemberDeletedEvent event) {
        List<RequiredFeedback> requiredFeedbacks =
            requiredFeedbackRepository.findByCallHistoryMemberIdAndDeletedFalse(event.memberId());
        List<DetailedFeedback> detailedFeedbacks =
            detailedFeedbackRepository.findByCallHistoryMemberIdAndDeletedFalse(event.memberId());
        // 부모가 없으면 빈 컬렉션으로 In 쿼리를 보내지 않는다
        if (!requiredFeedbacks.isEmpty()) {
            awkwardMomentRepository.findByRequiredFeedbackInAndDeletedFalse(requiredFeedbacks)
                .forEach(awkwardMoment -> awkwardMoment.delete(clock));
        }
        if (!detailedFeedbacks.isEmpty()) {
            startReasonRepository.findByDetailedFeedbackInAndDeletedFalse(detailedFeedbacks)
                .forEach(startReason -> startReason.delete(clock));
        }
        requiredFeedbacks.forEach(requiredFeedback -> requiredFeedback.delete(clock));
        detailedFeedbacks.forEach(detailedFeedback -> detailedFeedback.delete(clock));
    }

}
