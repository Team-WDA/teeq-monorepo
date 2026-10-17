package kr.co.teeq.api.call.application.service;

import java.util.UUID;
import kr.co.teeq.api.call.application.dto.response.CallStartResponse;
import kr.co.teeq.api.call.core.port.AiCallSession;
import kr.co.teeq.api.call.core.port.AiCallSessionPort;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * 통화 시작 흐름. AI 서버 호출 동안 DB 트랜잭션을 열지 않도록 이 클래스는 트랜잭션을 걸지 않는다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class CallService {

    private final CallLimitService callLimitService;
    private final CallHistoryService callHistoryService;
    private final AiCallSessionPort aiCallSessionPort;

    public CallStartResponse start(UUID memberId) {
        long allowedSeconds = callLimitService.checkStartable(memberId);
        UUID callHistoryId = callHistoryService.startPending(memberId);
        try {
            AiCallSession session = aiCallSessionPort.createSession(memberId, allowedSeconds);
            callHistoryService.activate(callHistoryId, session.callSessionId());
            return new CallStartResponse(session.callSessionId(), allowedSeconds, session.connection());
        } catch (RuntimeException exception) {
            failQuietly(callHistoryId, exception);
            throw exception;
        }
    }

    // 실패 처리 자체가 실패해도 원래 예외를 덮지 않는다
    private void failQuietly(UUID callHistoryId, RuntimeException cause) {
        try {
            callHistoryService.fail(callHistoryId);
        } catch (RuntimeException failure) {
            log.error("통화 기록 실패 처리에 실패했습니다. callHistoryId={}", callHistoryId, failure);
            cause.addSuppressed(failure);
        }
    }

}
