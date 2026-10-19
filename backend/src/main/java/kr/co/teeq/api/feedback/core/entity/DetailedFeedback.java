package kr.co.teeq.api.feedback.core.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import kr.co.teeq.api.call.core.entity.CallHistory;
import kr.co.teeq.api.common.core.entity.BaseEntity;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 통화 1회에 대한 상세 피드백. 통화당 한 건이다. 기억 점수는 기억 관련 대화가 없었으면(memoryNotApplicable) 없다.
 */
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
@Table(name = "detailed_feedback")
public class DetailedFeedback extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "call_history_id", nullable = false)
    private CallHistory callHistory;

    @Column(nullable = false)
    private int timingScore;

    @Column(length = 100)
    private String timingReason;

    @Column(nullable = false)
    private int personaFitScore;

    @Column(length = 100)
    private String personaFitReason;

    private Integer memoryScore;

    @Column(length = 100)
    private String memoryReason;

    @Column(nullable = false)
    private boolean memoryNotApplicable;

    @Column(nullable = false)
    private int empathyTrustScore;

    @Column(length = 100)
    private String empathyTrustReason;

    @Column(nullable = false)
    private int personalComfortScore;

    @Column(length = 100)
    private String personalComfortReason;

    @Column(nullable = false)
    private int storageComfortScore;

    @Column(length = 100)
    private String storageComfortReason;

    @Column(length = 1000)
    private String freeText;

    @Column(length = 100)
    private String startReasonOtherText;

    private DetailedFeedback(CallHistory callHistory,
        int timingScore, String timingReason,
        int personaFitScore, String personaFitReason,
        Integer memoryScore, String memoryReason, boolean memoryNotApplicable,
        int empathyTrustScore, String empathyTrustReason,
        int personalComfortScore, String personalComfortReason,
        int storageComfortScore, String storageComfortReason,
        String freeText, String startReasonOtherText) {
        this.callHistory = callHistory;
        this.timingScore = timingScore;
        this.timingReason = timingReason;
        this.personaFitScore = personaFitScore;
        this.personaFitReason = personaFitReason;
        this.memoryScore = memoryScore;
        this.memoryReason = memoryReason;
        this.memoryNotApplicable = memoryNotApplicable;
        this.empathyTrustScore = empathyTrustScore;
        this.empathyTrustReason = empathyTrustReason;
        this.personalComfortScore = personalComfortScore;
        this.personalComfortReason = personalComfortReason;
        this.storageComfortScore = storageComfortScore;
        this.storageComfortReason = storageComfortReason;
        this.freeText = freeText;
        this.startReasonOtherText = startReasonOtherText;
    }

    public static DetailedFeedback of(CallHistory callHistory,
        int timingScore, String timingReason,
        int personaFitScore, String personaFitReason,
        Integer memoryScore, String memoryReason, boolean memoryNotApplicable,
        int empathyTrustScore, String empathyTrustReason,
        int personalComfortScore, String personalComfortReason,
        int storageComfortScore, String storageComfortReason,
        String freeText, String startReasonOtherText) {
        return new DetailedFeedback(callHistory,
            timingScore, timingReason,
            personaFitScore, personaFitReason,
            memoryScore, memoryReason, memoryNotApplicable,
            empathyTrustScore, empathyTrustReason,
            personalComfortScore, personalComfortReason,
            storageComfortScore, storageComfortReason,
            freeText, startReasonOtherText);
    }

}
