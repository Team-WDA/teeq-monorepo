package kr.co.teeq.api.feedback.core.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import kr.co.teeq.api.call.core.entity.CallHistory;
import kr.co.teeq.api.common.core.entity.BaseEntity;
import kr.co.teeq.api.feedback.core.constant.PreviousCallRecall;
import kr.co.teeq.api.feedback.core.constant.RevisitIntention;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 통화 1회에 대한 필수 피드백. 통화당 한 건이다.
 */
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
@Table(name = "required_feedback")
public class RequiredFeedback extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "call_history_id", nullable = false)
    private CallHistory callHistory;

    @Column(nullable = false)
    private int rating;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private RevisitIntention revisitIntention;

    // 첫 통화에는 묻지 않으므로 없을 수 있다
    @Enumerated(EnumType.STRING)
    @Column(length = 20)
    private PreviousCallRecall previousCallRecall;

    private RequiredFeedback(CallHistory callHistory, int rating, RevisitIntention revisitIntention,
        PreviousCallRecall previousCallRecall) {
        this.callHistory = callHistory;
        this.rating = rating;
        this.revisitIntention = revisitIntention;
        this.previousCallRecall = previousCallRecall;
    }

    public static RequiredFeedback of(CallHistory callHistory, int rating, RevisitIntention revisitIntention,
        PreviousCallRecall previousCallRecall) {
        return new RequiredFeedback(callHistory, rating, revisitIntention, previousCallRecall);
    }

}
