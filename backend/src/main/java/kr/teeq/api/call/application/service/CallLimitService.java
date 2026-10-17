package kr.teeq.api.call.application.service;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.UUID;
import kr.teeq.api.call.application.dto.response.CallLimitStatusResponse;
import kr.teeq.api.call.core.repository.CallBonusRepository;
import kr.teeq.api.call.core.repository.CallHistoryRepository;
import kr.teeq.api.common.core.exception.CustomException;
import kr.teeq.api.common.core.exception.ErrorCode;
import kr.teeq.api.setting.application.service.SettingConfigService;
import kr.teeq.api.setting.core.constant.SettingKey;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class CallLimitService {

    private final CallHistoryRepository callHistoryRepository;
    private final CallBonusRepository callBonusRepository;
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
        // 관리자가 부여한 추가 시간은 해당 날짜에만 일 한도에 더해진다
        long bonusSeconds = callBonusRepository.sumActiveSeconds(memberId, today);

        // 관리자가 일 한도를 낮춰 사용량이 한도를 넘더라도 남은 시간은 음수가 되지 않는다
        long remainingSeconds = Math.max(0, maxSecondsPerDay + bonusSeconds - usedSeconds);
        long allowedSeconds = Math.min(maxSecondsPerSession, remainingSeconds);
        return new CallLimitStatusResponse(usedSeconds, remainingSeconds, allowedSeconds,
            remainingSeconds >= minStartSeconds);
    }

    // 통화를 시작할 수 있으면 이번 통화의 허용 시간(초)을 돌려준다.
    // 개인 일 한도가 부족하면 CALL_LIMIT_INSUFFICIENT, 서비스 월 한도가 부족하면 CALL_SERVICE_LIMIT_EXCEEDED로 거부한다
    @Transactional(readOnly = true)
    public long checkStartable(UUID memberId) {
        CallLimitStatusResponse status = getTodayStatus(memberId);
        if (!status.canStart()) {
            throw new CustomException(ErrorCode.CALL_LIMIT_INSUFFICIENT);
        }

        long monthRemainingSeconds = getMonthRemainingSeconds();
        long minStartSeconds = settingConfigService.getInt(SettingKey.CALL_MIN_START_SECONDS);
        if (monthRemainingSeconds < minStartSeconds) {
            throw new CustomException(ErrorCode.CALL_SERVICE_LIMIT_EXCEEDED);
        }
        return Math.min(status.allowedSeconds(), monthRemainingSeconds);
    }

    // 서비스 월 한도는 전체 회원 합산이며, 달은 KST 달력 월이고 통화 시작 시각이 속한 달에 집계한다
    private long getMonthRemainingSeconds() {
        long maxSecondsPerMonth = settingConfigService.getInt(SettingKey.CALL_MAX_SECONDS_PER_MONTH_TOTAL);
        LocalDate firstDayOfMonth = clock.instant().atZone(koreaZoneId).toLocalDate().withDayOfMonth(1);
        Instant monthStart = firstDayOfMonth.atStartOfDay(koreaZoneId).toInstant();
        Instant nextMonthStart = firstDayOfMonth.plusMonths(1).atStartOfDay(koreaZoneId).toInstant();
        long usedSeconds = callHistoryRepository.sumDurationSecondsOfAllMembers(monthStart, nextMonthStart);
        return Math.max(0, maxSecondsPerMonth - usedSeconds);
    }

}
