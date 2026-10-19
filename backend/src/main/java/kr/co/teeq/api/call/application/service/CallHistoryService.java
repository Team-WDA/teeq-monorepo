package kr.co.teeq.api.call.application.service;

import java.time.Clock;
import java.time.Instant;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import kr.co.teeq.api.call.application.dto.request.CallUsageReportRequest;
import kr.co.teeq.api.call.application.dto.response.CallHistoryResponse;
import kr.co.teeq.api.call.core.constant.CallStatus;
import kr.co.teeq.api.call.core.entity.CallHistory;
import kr.co.teeq.api.call.core.repository.CallHistoryRepository;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.setting.application.service.SettingConfigService;
import kr.co.teeq.api.setting.core.constant.SettingKey;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 통화 기록의 상태 변경을 트랜잭션 단위로 처리한다. AI 서버 호출 동안 트랜잭션이 열리지 않도록 메서드마다 짧게 끝낸다.
 */
@Service
@RequiredArgsConstructor
public class CallHistoryService {

    private static final Set<CallStatus> ACTIVE_STATUSES = Set.of(CallStatus.PENDING, CallStatus.IN_PROGRESS);

    private final CallHistoryRepository callHistoryRepository;
    private final SettingConfigService settingConfigService;
    private final Clock clock;

    // 1회 한도를 넘긴 활성 기록을 만료시켜 자리를 비운 뒤, AI 서버 호출 전에 PENDING 기록을 선삽입한다
    @Transactional
    public UUID startPending(Member member) {
        Instant now = clock.instant();
        long maxSecondsPerSession = settingConfigService.getInt(SettingKey.CALL_MAX_SECONDS_PER_SESSION);
        // startedAt + 1회 한도 <= 지금 이면 만료 대상이므로 cutoff 이하(포함)로 조회한다
        Instant expiryCutoff = now.minusSeconds(maxSecondsPerSession);
        List<CallHistory> expiredCandidates = callHistoryRepository
            .findByMemberIdAndStatusInAndStartedAtLessThanEqualAndDeletedFalse(
                member.getId(), ACTIVE_STATUSES, expiryCutoff);
        expiredCandidates.forEach(CallHistory::expire);
        // UPDATE가 INSERT보다 먼저 나가야 회원당 활성 1건 partial unique index에 걸리지 않는다
        callHistoryRepository.flush();
        try {
            return callHistoryRepository.saveAndFlush(CallHistory.pending(member, now)).getId();
        } catch (DataIntegrityViolationException exception) {
            throw new CustomException(ErrorCode.CALL_ALREADY_IN_PROGRESS, exception);
        }
    }

    @Transactional
    public void activate(UUID callHistoryId, String callSessionId) {
        findCallHistory(callHistoryId).activate(callSessionId);
    }

    @Transactional
    public void fail(UUID callHistoryId) {
        findCallHistory(callHistoryId).fail();
    }

    // 이미 종료된 기록은 변경 없이 돌려주고(첫 보고 유지), IN_PROGRESS·EXPIRED 기록은 1회 한도로 잘라 종료 처리한다
    @Transactional
    public CallHistoryResponse reportUsage(String callSessionId, CallUsageReportRequest request) {
        CallHistory callHistory = callHistoryRepository.findWithLockByCallSessionIdAndDeletedFalse(callSessionId)
            .orElseThrow(() -> new CustomException(ErrorCode.CALL_SESSION_NOT_FOUND));
        if (callHistory.getStatus() != CallStatus.ENDED) {
            long maxSecondsPerSession = settingConfigService.getInt(SettingKey.CALL_MAX_SECONDS_PER_SESSION);
            int usedSeconds = (int) Math.min(request.usedSeconds(), maxSecondsPerSession);
            callHistory.end(usedSeconds, request.endedAt());
        }
        return CallHistoryResponse.from(callHistory);
    }

    private CallHistory findCallHistory(UUID callHistoryId) {
        return callHistoryRepository.findByIdAndDeletedFalse(callHistoryId)
            .orElseThrow(() -> new CustomException(ErrorCode.RESOURCE_NOT_FOUND));
    }

}
