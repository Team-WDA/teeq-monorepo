package kr.co.teeq.api.feedback.application.dto.response;

import java.util.List;
import kr.co.teeq.api.feedback.core.constant.AwkwardMoment;
import kr.co.teeq.api.feedback.core.constant.PreviousCallRecall;
import kr.co.teeq.api.feedback.core.constant.RevisitIntention;
import kr.co.teeq.api.feedback.core.constant.StartReason;

/**
 * 통화 한 건의 피드백. 필수 피드백은 항상 있고, 상세 피드백은 제출하지 않았으면 null이다.
 */
public record CallFeedbackResponse(
    RequiredPart required,
    DetailedPart detailed
) {

    // 지난 통화 기억 여부는 첫 통화에는 묻지 않아 null일 수 있다. 어색했던 순간은 선택지 선언 순서다
    public record RequiredPart(
        int rating,
        RevisitIntention revisitIntention,
        PreviousCallRecall previousCallRecall,
        List<AwkwardMoment> awkwardMoments
    ) {

    }

    // 기억 관련 대화가 없었으면(memoryNotApplicable) 기억 점수·사유가 없다. 시작 이유는 선택지 선언 순서다
    public record DetailedPart(
        int timingScore,
        String timingReason,
        int personaFitScore,
        String personaFitReason,
        Integer memoryScore,
        String memoryReason,
        boolean memoryNotApplicable,
        int empathyTrustScore,
        String empathyTrustReason,
        int personalComfortScore,
        String personalComfortReason,
        int storageComfortScore,
        String storageComfortReason,
        String freeText,
        List<StartReason> startReasons,
        String startReasonOtherText
    ) {

    }

}
