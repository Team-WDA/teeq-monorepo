package kr.co.teeq.api.call.application.service;

import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import kr.co.teeq.api.call.application.dto.response.FeedbackTargetCall;
import kr.co.teeq.api.call.application.dto.response.LatestFeedbackableCall;
import kr.co.teeq.api.call.core.constant.CallStatus;
import kr.co.teeq.api.call.core.entity.CallHistory;
import kr.co.teeq.api.call.core.repository.CallHistoryRepository;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 피드백 도메인이 사용하는 대상 통화 조회. 상태를 바꾸지 않으므로 잠금 없이 읽기 전용으로 조회한다.
 */
@Service
@RequiredArgsConstructor
public class CallFeedbackTargetService {

    private static final Set<CallStatus> FEEDBACKABLE_STATUSES = Set.of(CallStatus.ENDED, CallStatus.EXPIRED);

    private final CallHistoryRepository callHistoryRepository;

    // 본인 통화가 아니거나 없으면 존재 여부를 숨기려고 같은 404로 응답한다
    @Transactional(readOnly = true)
    public FeedbackTargetCall getFeedbackTarget(UUID memberId, String callSessionId) {
        CallHistory callHistory = callHistoryRepository.findByCallSessionIdAndDeletedFalse(callSessionId)
            .filter(found -> found.getMemberId().equals(memberId))
            .orElseThrow(() -> new CustomException(ErrorCode.CALL_SESSION_NOT_FOUND));
        if (!FEEDBACKABLE_STATUSES.contains(callHistory.getStatus())) {
            throw new CustomException(ErrorCode.CALL_NOT_FEEDBACKABLE);
        }
        return new FeedbackTargetCall(callHistory.getId(), countCallIndex(memberId, callHistory));
    }

    // 피드백 가능한(종료·만료) 통화 중 가장 최근 것. 없으면 empty
    @Transactional(readOnly = true)
    public Optional<LatestFeedbackableCall> findLatestFeedbackableCall(UUID memberId) {
        return callHistoryRepository
            .findFirstByMemberIdAndStatusInAndDeletedFalseOrderByStartedAtDesc(memberId, FEEDBACKABLE_STATUSES)
            .map(callHistory -> new LatestFeedbackableCall(
                callHistory.getId(), callHistory.getCallSessionId(), countCallIndex(memberId, callHistory)));
    }

    private int countCallIndex(UUID memberId, CallHistory callHistory) {
        long callIndex = callHistoryRepository.countByMemberIdAndStatusNotAndStartedAtLessThanEqualAndDeletedFalse(
            memberId, CallStatus.FAILED, callHistory.getStartedAt());
        return Math.toIntExact(callIndex);
    }

}
