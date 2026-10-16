package kr.teeq.api.feedback.core.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import kr.teeq.api.common.core.entity.BaseEntity;
import kr.teeq.api.feedback.core.constant.StartReason;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 상세 피드백에서 고른 통화 시작 이유 1건. 선택지 하나당 한 행이다.
 */
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
@Table(name = "detailed_feedback_start_reason")
public class DetailedFeedbackStartReason extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "detailed_feedback_id", nullable = false)
    private DetailedFeedback detailedFeedback;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private StartReason startReason;

    private DetailedFeedbackStartReason(DetailedFeedback detailedFeedback, StartReason startReason) {
        this.detailedFeedback = detailedFeedback;
        this.startReason = startReason;
    }

    public static DetailedFeedbackStartReason of(DetailedFeedback detailedFeedback, StartReason startReason) {
        return new DetailedFeedbackStartReason(detailedFeedback, startReason);
    }

}
