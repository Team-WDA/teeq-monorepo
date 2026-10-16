package kr.teeq.api.feedback.application.service;

import java.util.HashSet;
import java.util.List;
import java.util.UUID;
import kr.teeq.api.call.application.dto.response.FeedbackTargetCall;
import kr.teeq.api.call.application.service.CallFeedbackTargetService;
import kr.teeq.api.common.core.exception.CustomException;
import kr.teeq.api.common.core.exception.ErrorCode;
import kr.teeq.api.feedback.application.dto.request.DetailedFeedbackRequest;
import kr.teeq.api.feedback.application.dto.request.RequiredFeedbackRequest;
import kr.teeq.api.feedback.application.dto.response.FeedbackStatusResponse;
import kr.teeq.api.feedback.application.dto.response.RequiredFeedbackResponse;
import kr.teeq.api.feedback.core.constant.AwkwardMoment;
import kr.teeq.api.feedback.core.constant.FeedbackRule;
import kr.teeq.api.feedback.core.constant.StartReason;
import kr.teeq.api.feedback.core.entity.DetailedFeedback;
import kr.teeq.api.feedback.core.entity.DetailedFeedbackStartReason;
import kr.teeq.api.feedback.core.entity.RequiredFeedback;
import kr.teeq.api.feedback.core.entity.RequiredFeedbackAwkwardMoment;
import kr.teeq.api.feedback.core.repository.DetailedFeedbackRepository;
import kr.teeq.api.feedback.core.repository.DetailedFeedbackStartReasonRepository;
import kr.teeq.api.feedback.core.repository.RequiredFeedbackAwkwardMomentRepository;
import kr.teeq.api.feedback.core.repository.RequiredFeedbackRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 통화 후 필수 피드백과 상세 피드백의 상태 조회·제출을 처리한다.
 */
@Service
@RequiredArgsConstructor
public class CallFeedbackService {

    private final CallFeedbackTargetService callFeedbackTargetService;
    private final RequiredFeedbackRepository requiredFeedbackRepository;
    private final RequiredFeedbackAwkwardMomentRepository requiredFeedbackAwkwardMomentRepository;
    private final DetailedFeedbackRepository detailedFeedbackRepository;
    private final DetailedFeedbackStartReasonRepository detailedFeedbackStartReasonRepository;

    @Transactional(readOnly = true)
    public FeedbackStatusResponse getStatus(UUID memberId, String callSessionId) {
        FeedbackTargetCall target = callFeedbackTargetService.getFeedbackTarget(memberId, callSessionId);
        return new FeedbackStatusResponse(
            target.callIndex(),
            FeedbackRule.isPreviousCallRecallRequired(target.callIndex()),
            requiredFeedbackRepository.existsByCallHistoryIdAndDeletedFalse(target.callHistoryId()));
    }

    @Transactional
    public RequiredFeedbackResponse submitRequired(UUID memberId, String callSessionId,
        RequiredFeedbackRequest request) {
        FeedbackTargetCall target = callFeedbackTargetService.getFeedbackTarget(memberId, callSessionId);
        if (requiredFeedbackRepository.existsByCallHistoryIdAndDeletedFalse(target.callHistoryId())) {
            throw new CustomException(ErrorCode.FEEDBACK_ALREADY_SUBMITTED);
        }
        validatePreviousCallRecall(request, target.callIndex());
        validateAwkwardMoments(request.awkwardMoments());

        RequiredFeedback requiredFeedback = saveRequiredFeedback(RequiredFeedback.of(
            target.callHistoryId(), request.rating(), request.revisitIntention(), request.previousCallRecall()));
        requiredFeedbackAwkwardMomentRepository.saveAll(request.awkwardMoments().stream()
            .map(awkwardMoment -> RequiredFeedbackAwkwardMoment.of(requiredFeedback, awkwardMoment))
            .toList());
        return new RequiredFeedbackResponse(FeedbackRule.isDetailedFeedbackInvited(target.callIndex()));
    }

    @Transactional
    public void submitDetailed(UUID memberId, String callSessionId, DetailedFeedbackRequest request) {
        FeedbackTargetCall target = callFeedbackTargetService.getFeedbackTarget(memberId, callSessionId);
        validateDetailedFeedbackSubmittable(target);
        DetailedFeedbackRequest normalized = normalize(request);
        validateMemory(normalized);
        validateStartReasons(normalized);

        DetailedFeedback detailedFeedback = saveDetailedFeedback(toEntity(target.callHistoryId(), normalized));
        detailedFeedbackStartReasonRepository.saveAll(normalized.startReasons().stream()
            .map(startReason -> DetailedFeedbackStartReason.of(detailedFeedback, startReason))
            .toList());
    }

    private void validateDetailedFeedbackSubmittable(FeedbackTargetCall target) {
        if (!requiredFeedbackRepository.existsByCallHistoryIdAndDeletedFalse(target.callHistoryId())) {
            throw new CustomException(ErrorCode.REQUIRED_FEEDBACK_NOT_SUBMITTED);
        }
        if (!FeedbackRule.isDetailedFeedbackInvited(target.callIndex())) {
            throw new CustomException(ErrorCode.DETAILED_FEEDBACK_NOT_INVITED);
        }
        if (detailedFeedbackRepository.existsByCallHistoryIdAndDeletedFalse(target.callHistoryId())) {
            throw new CustomException(ErrorCode.FEEDBACK_ALREADY_SUBMITTED);
        }
    }

    // 첫 통화에는 지난 통화가 없으므로 기억 문항이 오면 안 되고, 이후에는 반드시 와야 한다
    private void validatePreviousCallRecall(RequiredFeedbackRequest request, int callIndex) {
        boolean required = FeedbackRule.isPreviousCallRecallRequired(callIndex);
        if (required != (request.previousCallRecall() != null)) {
            throw new CustomException(ErrorCode.INVALID_FEEDBACK_ANSWER);
        }
    }

    private void validateAwkwardMoments(List<AwkwardMoment> awkwardMoments) {
        if (new HashSet<>(awkwardMoments).size() != awkwardMoments.size()) {
            throw new CustomException(ErrorCode.INVALID_FEEDBACK_ANSWER);
        }
        if (awkwardMoments.contains(AwkwardMoment.NONE) && awkwardMoments.size() > 1) {
            throw new CustomException(ErrorCode.INVALID_FEEDBACK_ANSWER);
        }
    }

    // 기억 문항을 건너뛰었으면 점수·사유가 없어야 하고, 건너뛰지 않았으면 점수가 있어야 한다
    private void validateMemory(DetailedFeedbackRequest request) {
        boolean skipped = request.memoryNotApplicable();
        boolean hasMemoryAnswer = request.memoryScore() != null || request.memoryReason() != null;
        if (skipped && hasMemoryAnswer) {
            throw new CustomException(ErrorCode.INVALID_FEEDBACK_ANSWER);
        }
        if (!skipped && request.memoryScore() == null) {
            throw new CustomException(ErrorCode.INVALID_FEEDBACK_ANSWER);
        }
    }

    private void validateStartReasons(DetailedFeedbackRequest request) {
        List<StartReason> startReasons = request.startReasons();
        if (new HashSet<>(startReasons).size() != startReasons.size()) {
            throw new CustomException(ErrorCode.INVALID_FEEDBACK_ANSWER);
        }
        if (request.startReasonOtherText() != null && !startReasons.contains(StartReason.OTHER)) {
            throw new CustomException(ErrorCode.INVALID_FEEDBACK_ANSWER);
        }
    }

    // 동시 요청으로 사전 존재 확인을 통과해도 통화당 1건 unique 제약이 막는다
    private RequiredFeedback saveRequiredFeedback(RequiredFeedback requiredFeedback) {
        try {
            return requiredFeedbackRepository.saveAndFlush(requiredFeedback);
        } catch (DataIntegrityViolationException exception) {
            throw new CustomException(ErrorCode.FEEDBACK_ALREADY_SUBMITTED, exception);
        }
    }

    private DetailedFeedback saveDetailedFeedback(DetailedFeedback detailedFeedback) {
        try {
            return detailedFeedbackRepository.saveAndFlush(detailedFeedback);
        } catch (DataIntegrityViolationException exception) {
            throw new CustomException(ErrorCode.FEEDBACK_ALREADY_SUBMITTED, exception);
        }
    }

    private DetailedFeedback toEntity(UUID callHistoryId, DetailedFeedbackRequest request) {
        return DetailedFeedback.of(callHistoryId,
            request.timingScore(), request.timingReason(),
            request.personaFitScore(), request.personaFitReason(),
            request.memoryScore(), request.memoryReason(), request.memoryNotApplicable(),
            request.empathyTrustScore(), request.empathyTrustReason(),
            request.personalComfortScore(), request.personalComfortReason(),
            request.storageComfortScore(), request.storageComfortReason(),
            request.freeText(), request.startReasonOtherText());
    }

    // 공백뿐인 문자열은 값이 없는 것으로 보고 앞뒤 공백을 제거한다
    private DetailedFeedbackRequest normalize(DetailedFeedbackRequest request) {
        return new DetailedFeedbackRequest(
            request.timingScore(), blankToNull(request.timingReason()),
            request.personaFitScore(), blankToNull(request.personaFitReason()),
            request.memoryScore(), blankToNull(request.memoryReason()), request.memoryNotApplicable(),
            request.empathyTrustScore(), blankToNull(request.empathyTrustReason()),
            request.personalComfortScore(), blankToNull(request.personalComfortReason()),
            request.storageComfortScore(), blankToNull(request.storageComfortReason()),
            blankToNull(request.freeText()), request.startReasons(), blankToNull(request.startReasonOtherText()));
    }

    private String blankToNull(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.strip();
    }

}
