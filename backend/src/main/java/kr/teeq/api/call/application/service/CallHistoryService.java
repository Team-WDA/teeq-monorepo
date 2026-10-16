package kr.teeq.api.call.application.service;

import java.util.Optional;
import kr.teeq.api.call.application.dto.request.CallHistoryRecordRequest;
import kr.teeq.api.call.application.dto.response.CallHistoryRecordResult;
import kr.teeq.api.call.application.dto.response.CallHistoryResponse;
import kr.teeq.api.call.core.entity.CallHistory;
import kr.teeq.api.call.core.repository.CallHistoryRepository;
import kr.teeq.api.common.core.exception.CustomException;
import kr.teeq.api.common.core.exception.ErrorCode;
import kr.teeq.api.member.core.repository.MemberRepository;
import kr.teeq.api.setting.application.service.SettingConfigService;
import kr.teeq.api.setting.core.constant.SettingKey;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class CallHistoryService {

    private final CallHistoryRepository callHistoryRepository;
    private final MemberRepository memberRepository;
    private final SettingConfigService settingConfigService;

    // @Transactional을 붙이지 않는다. unique 위반이 난 트랜잭션은 PostgreSQL에서 중단되어
    // 같은 트랜잭션 안에서는 기존 행을 다시 조회할 수 없으므로, 리포지토리 호출마다 각자 트랜잭션을 쓴다
    public CallHistoryRecordResult record(CallHistoryRecordRequest request) {
        memberRepository.findByIdAndDeletedFalse(request.memberId())
            .orElseThrow(() -> new CustomException(ErrorCode.MEMBER_NOT_FOUND));

        // 같은 통화 세션이 이미 기록되어 있으면 새 값으로 덮어쓰지 않고 저장된 값을 그대로 돌려준다
        Optional<CallHistory> existing = callHistoryRepository.findByCallSessionIdAndDeletedFalse(
            request.callSessionId());
        if (existing.isPresent()) {
            return toResult(existing.get(), false);
        }

        long maxSecondsPerSession = settingConfigService.getInt(SettingKey.CALL_MAX_SECONDS_PER_SESSION);
        int durationSeconds = (int) Math.min(request.durationSeconds(), maxSecondsPerSession);
        CallHistory callHistory = CallHistory.builder()
            .memberId(request.memberId())
            .callSessionId(request.callSessionId())
            .startedAt(request.startedAt())
            .durationSeconds(durationSeconds)
            .build();
        try {
            return toResult(callHistoryRepository.saveAndFlush(callHistory), true);
        } catch (DataIntegrityViolationException exception) {
            // 동시에 같은 세션이 먼저 저장된 경우만 중복으로 처리하고, 그 외 무결성 오류는 그대로 던진다
            return callHistoryRepository.findByCallSessionIdAndDeletedFalse(request.callSessionId())
                .map(duplicated -> toResult(duplicated, false))
                .orElseThrow(() -> exception);
        }
    }

    private CallHistoryRecordResult toResult(CallHistory callHistory, boolean created) {
        return new CallHistoryRecordResult(CallHistoryResponse.from(callHistory), created);
    }

}
