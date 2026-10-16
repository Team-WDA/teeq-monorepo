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
import kr.teeq.api.feedback.core.constant.AwkwardMoment;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 필수 피드백에서 고른 어색했던 순간 1건. 선택지 하나당 한 행이다.
 */
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
@Table(name = "required_feedback_awkward_moment")
public class RequiredFeedbackAwkwardMoment extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "required_feedback_id", nullable = false)
    private RequiredFeedback requiredFeedback;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private AwkwardMoment awkwardMoment;

    private RequiredFeedbackAwkwardMoment(RequiredFeedback requiredFeedback, AwkwardMoment awkwardMoment) {
        this.requiredFeedback = requiredFeedback;
        this.awkwardMoment = awkwardMoment;
    }

    public static RequiredFeedbackAwkwardMoment of(RequiredFeedback requiredFeedback, AwkwardMoment awkwardMoment) {
        return new RequiredFeedbackAwkwardMoment(requiredFeedback, awkwardMoment);
    }

}
