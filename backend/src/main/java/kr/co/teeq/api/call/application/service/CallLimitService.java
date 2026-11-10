package kr.co.teeq.api.call.application.service;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.UUID;
import kr.co.teeq.api.call.application.dto.response.CallLimitStatusResponse;
import kr.co.teeq.api.call.application.dto.response.MemberTodayCallLimitResponse;
import kr.co.teeq.api.call.core.constant.CallLimitDecision;
import kr.co.teeq.api.call.core.repository.CallBonusRepository;
import kr.co.teeq.api.call.core.repository.CallHistoryRepository;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.repository.MemberRepository;
import kr.co.teeq.api.setting.application.service.SettingConfigService;
import kr.co.teeq.api.setting.core.constant.SettingKey;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class CallLimitService {

    private final CallHistoryRepository callHistoryRepository;
    private final CallBonusRepository callBonusRepository;
    private final SettingConfigService settingConfigService;
    private final MemberRepository memberRepository;
    private final Clock clock;
    private final ZoneId koreaZoneId;

    // 호출자가 인증된 본인이므로 회원 존재는 확인하지 않는다
    @Transactional(readOnly = true)
    public CallLimitStatusResponse getTodayStatus(Member member) {
        long maxSecondsPerSession = settingConfigService.getInt(SettingKey.CALL_MAX_SECONDS_PER_SESSION);
        long minStartSeconds = settingConfigService.getInt(SettingKey.CALL_MIN_START_SECONDS);

        MemberTodayCallLimitResponse todayLimit = calculateTodayLimit(member);
        long remainingSeconds = todayLimit.remainingSeconds();
        long allowedSeconds = Math.min(maxSecondsPerSession, remainingSeconds);
        return new CallLimitStatusResponse(todayLimit.usedSeconds(), remainingSeconds, allowedSeconds,
            remainingSeconds >= minStartSeconds);
    }

    // 관리자 화면용: 회원 id로 조회한 회원의 오늘 한도 현황. 계산은 getTodayStatus와 같다
    @Transactional(readOnly = true)
    public MemberTodayCallLimitResponse getTodayLimit(UUID memberId) {
        Member member = memberRepository.findByIdAndDeletedFalse(memberId)
            .orElseThrow(() -> new CustomException(ErrorCode.MEMBER_NOT_FOUND));
        return calculateTodayLimit(member);
    }

    // 통화를 시작할 수 있으면 이번 통화의 허용 시간(초)과 그 값을 정한 한도의 종류를 돌려준다.
    // 개인 일 한도가 부족하면 CALL_LIMIT_INSUFFICIENT, 서비스 월 한도가 부족하면 CALL_SERVICE_LIMIT_EXCEEDED로 거부한다
    @Transactional(readOnly = true)
    public CallLimitDecision checkStartable(Member member) {
        CallLimitStatusResponse status = getTodayStatus(member);
        if (!status.canStart()) {
            throw new CustomException(ErrorCode.CALL_LIMIT_INSUFFICIENT);
        }

        long monthRemainingSeconds = getMonthRemainingSeconds();
        long minStartSeconds = settingConfigService.getInt(SettingKey.CALL_MIN_START_SECONDS);
        if (monthRemainingSeconds < minStartSeconds) {
            throw new CustomException(ErrorCode.CALL_SERVICE_LIMIT_EXCEEDED);
        }
        long perCallSeconds = settingConfigService.getInt(SettingKey.CALL_MAX_SECONDS_PER_SESSION);
        // allowedSeconds는 이미 1회 한도로 잘려 있어 PER_CALL과 PER_DAY를 구분할 수 없으므로 일 잔여 시간을 그대로 쓴다
        return CallLimitDecision.of(perCallSeconds, status.remainingSeconds(), monthRemainingSeconds);
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

    private MemberTodayCallLimitResponse calculateTodayLimit(Member member) {
        long maxSecondsPerDay = settingConfigService.getInt(SettingKey.CALL_MAX_SECONDS_PER_DAY);

        // 하루는 KST 0시 기준이며, 통화 시작 시각이 속한 날에 전체 시간을 집계한다
        LocalDate today = clock.instant().atZone(koreaZoneId).toLocalDate();
        Instant todayStart = today.atStartOfDay(koreaZoneId).toInstant();
        Instant tomorrowStart = today.plusDays(1).atStartOfDay(koreaZoneId).toInstant();
        long usedSeconds = callHistoryRepository.sumDurationSeconds(member.getId(), todayStart, tomorrowStart);
        // 관리자가 부여한 추가 시간은 해당 날짜에만 일 한도에 더해진다
        long bonusSeconds = callBonusRepository.sumActiveSeconds(member.getId(), today);

        // 관리자가 일 한도를 낮춰 사용량이 한도를 넘더라도 남은 시간은 음수가 되지 않는다
        long remainingSeconds = Math.max(0, maxSecondsPerDay + bonusSeconds - usedSeconds);
        return new MemberTodayCallLimitResponse(maxSecondsPerDay, bonusSeconds, usedSeconds, remainingSeconds);
    }

}
