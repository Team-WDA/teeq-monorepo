package kr.teeq.api.call.application.service;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.UUID;
import kr.teeq.api.call.application.dto.response.CallLimitStatusResponse;
import kr.teeq.api.call.core.repository.CallHistoryRepository;
import kr.teeq.api.common.core.exception.CustomException;
import kr.teeq.api.common.core.exception.ErrorCode;
import kr.teeq.api.member.core.repository.MemberRepository;
import kr.teeq.api.setting.application.service.SettingConfigService;
import kr.teeq.api.setting.core.constant.SettingKey;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class CallLimitService {

    private final CallHistoryRepository callHistoryRepository;
    private final MemberRepository memberRepository;
    private final SettingConfigService settingConfigService;
    private final Clock clock;
    private final ZoneId koreaZoneId;

    // 호출자가 인증된 본인이므로 회원 존재는 확인하지 않는다
    @Transactional(readOnly = true)
    public CallLimitStatusResponse getTodayStatus(UUID memberId) {
        long maxSecondsPerSession = settingConfigService.getInt(SettingKey.CALL_MAX_SECONDS_PER_SESSION);
        long maxSecondsPerDay = settingConfigService.getInt(SettingKey.CALL_MAX_SECONDS_PER_DAY);
        long minStartSeconds = settingConfigService.getInt(SettingKey.CALL_MIN_START_SECONDS);

        // 하루는 KST 0시 기준이며, 통화 시작 시각이 속한 날에 전체 시간을 집계한다
        LocalDate today = clock.instant().atZone(koreaZoneId).toLocalDate();
        Instant todayStart = today.atStartOfDay(koreaZoneId).toInstant();
        Instant tomorrowStart = today.plusDays(1).atStartOfDay(koreaZoneId).toInstant();
        long usedSeconds = callHistoryRepository.sumDurationSeconds(memberId, todayStart, tomorrowStart);

        // 관리자가 일 한도를 낮춰 사용량이 한도를 넘더라도 남은 시간은 음수가 되지 않는다
        long remainingSeconds = Math.max(0, maxSecondsPerDay - usedSeconds);
        long allowedSeconds = Math.min(maxSecondsPerSession, remainingSeconds);
        return new CallLimitStatusResponse(usedSeconds, remainingSeconds, allowedSeconds,
            remainingSeconds >= minStartSeconds);
    }

    // 통화를 시작할 수 있으면 이번 통화의 허용 시간(초)을 돌려주고, 부족하면 CALL_LIMIT_INSUFFICIENT로 거부한다
    @Transactional(readOnly = true)
    public long checkStartable(UUID memberId) {
        memberRepository.findByIdAndDeletedFalse(memberId)
            .orElseThrow(() -> new CustomException(ErrorCode.MEMBER_NOT_FOUND));
        CallLimitStatusResponse status = getTodayStatus(memberId);
        if (!status.canStart()) {
            throw new CustomException(ErrorCode.CALL_LIMIT_INSUFFICIENT);
        }
        return status.allowedSeconds();
    }

}
