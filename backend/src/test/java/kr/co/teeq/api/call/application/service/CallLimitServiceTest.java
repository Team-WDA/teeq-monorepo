package kr.co.teeq.api.call.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.BDDMockito.given;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.UUID;
import kr.co.teeq.api.call.application.dto.response.CallLimitStatusResponse;
import kr.co.teeq.api.call.core.repository.CallBonusRepository;
import kr.co.teeq.api.call.core.repository.CallHistoryRepository;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.setting.application.service.SettingConfigService;
import kr.co.teeq.api.setting.core.constant.SettingKey;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class CallLimitServiceTest {

    private static final ZoneId KOREA_ZONE_ID = ZoneId.of("Asia/Seoul");
    private static final Instant NOON_KST = Instant.parse("2026-10-16T03:00:00Z");
    private static final Instant TODAY_START = Instant.parse("2026-10-15T15:00:00Z");
    private static final Instant TODAY_END = Instant.parse("2026-10-16T15:00:00Z");
    private static final LocalDate TODAY = LocalDate.of(2026, 10, 16);
    // 2026-10-16(KST)이 속한 달 [10월 1일 0시, 11월 1일 0시)
    private static final Instant MONTH_START = Instant.parse("2026-09-30T15:00:00Z");
    private static final Instant MONTH_END = Instant.parse("2026-10-31T15:00:00Z");

    private final UUID memberId = UUID.randomUUID();

    @Mock
    private CallHistoryRepository callHistoryRepository;

    @Mock
    private CallBonusRepository callBonusRepository;

    @Mock
    private SettingConfigService settingConfigService;

    private CallLimitService createService(Instant now) {
        return new CallLimitService(callHistoryRepository, callBonusRepository, settingConfigService,
            Clock.fixed(now, ZoneOffset.UTC), KOREA_ZONE_ID);
    }

    private void stubSettings() {
        given(settingConfigService.getInt(SettingKey.CALL_MAX_SECONDS_PER_SESSION)).willReturn(1200L);
        given(settingConfigService.getInt(SettingKey.CALL_MAX_SECONDS_PER_DAY)).willReturn(1800L);
        given(settingConfigService.getInt(SettingKey.CALL_MIN_START_SECONDS)).willReturn(60L);
    }

    private void stubUsedSeconds(long usedSeconds) {
        given(callHistoryRepository.sumDurationSeconds(memberId, TODAY_START, TODAY_END)).willReturn(usedSeconds);
        given(callBonusRepository.sumActiveSeconds(memberId, TODAY)).willReturn(0L);
    }

    private void stubBonusSeconds(long bonusSeconds) {
        given(callBonusRepository.sumActiveSeconds(memberId, TODAY)).willReturn(bonusSeconds);
    }

    private void stubMonth(long monthLimitSeconds, long monthUsedSeconds) {
        given(settingConfigService.getInt(SettingKey.CALL_MAX_SECONDS_PER_MONTH_TOTAL)).willReturn(monthLimitSeconds);
        given(callHistoryRepository.sumDurationSecondsOfAllMembers(MONTH_START, MONTH_END))
            .willReturn(monthUsedSeconds);
    }

    @Test
    void getTodayStatus_noUsage_returnsFullAllowance() {
        stubSettings();
        stubUsedSeconds(0);

        CallLimitStatusResponse response = createService(NOON_KST).getTodayStatus(memberId);

        assertThat(response).isEqualTo(new CallLimitStatusResponse(0, 1800, 1200, true));
    }

    @Test
    void getTodayStatus_remainingBelowSessionLimit_capsAllowedSeconds() {
        stubSettings();
        stubUsedSeconds(1500);

        CallLimitStatusResponse response = createService(NOON_KST).getTodayStatus(memberId);

        assertThat(response).isEqualTo(new CallLimitStatusResponse(1500, 300, 300, true));
    }

    @Test
    void getTodayStatus_remaining59_cannotStart() {
        stubSettings();
        stubUsedSeconds(1741);

        CallLimitStatusResponse response = createService(NOON_KST).getTodayStatus(memberId);

        assertThat(response.remainingSeconds()).isEqualTo(59);
        assertThat(response.canStart()).isFalse();
    }

    @Test
    void getTodayStatus_remaining60_canStart() {
        stubSettings();
        stubUsedSeconds(1740);

        CallLimitStatusResponse response = createService(NOON_KST).getTodayStatus(memberId);

        assertThat(response.remainingSeconds()).isEqualTo(60);
        assertThat(response.canStart()).isTrue();
    }

    @Test
    void getTodayStatus_usedExceedsDailyLimit_remainingIsZero() {
        stubSettings();
        stubUsedSeconds(2000);

        CallLimitStatusResponse response = createService(NOON_KST).getTodayStatus(memberId);

        assertThat(response.remainingSeconds()).isZero();
        assertThat(response.allowedSeconds()).isZero();
        assertThat(response.canStart()).isFalse();
    }

    @Test
    void getTodayStatus_beforeKstMidnight_queriesCurrentKstDay() {
        stubSettings();
        stubUsedSeconds(0);

        createService(Instant.parse("2026-10-16T14:59:59Z")).getTodayStatus(memberId);

        // 리포지토리에 넘긴 경계 인자가 KST 당일 [0시, 다음날 0시)인지 확인한다
        verify(callHistoryRepository).sumDurationSeconds(memberId, TODAY_START, TODAY_END);
    }

    @Test
    void getTodayStatus_atKstMidnight_queriesNextKstDay() {
        stubSettings();
        Instant nextDayStart = Instant.parse("2026-10-16T15:00:00Z");
        Instant nextDayEnd = Instant.parse("2026-10-17T15:00:00Z");
        given(callHistoryRepository.sumDurationSeconds(memberId, nextDayStart, nextDayEnd)).willReturn(0L);
        given(callBonusRepository.sumActiveSeconds(memberId, LocalDate.of(2026, 10, 17))).willReturn(0L);

        createService(Instant.parse("2026-10-16T15:00:00Z")).getTodayStatus(memberId);

        verify(callHistoryRepository).sumDurationSeconds(memberId, nextDayStart, nextDayEnd);
    }

    @Test
    void checkStartable_enoughTime_returnsAllowedSeconds() {
        stubSettings();
        stubUsedSeconds(1500);
        stubMonth(900000, 0);

        long allowedSeconds = createService(NOON_KST).checkStartable(memberId);

        assertThat(allowedSeconds).isEqualTo(300);
    }

    @Test
    void checkStartable_insufficient_throwsCallLimitInsufficient() {
        stubSettings();
        stubUsedSeconds(1741);

        assertThatThrownBy(() -> createService(NOON_KST).checkStartable(memberId))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.CALL_LIMIT_INSUFFICIENT));
    }

    @Test
    void getTodayStatus_withBonus_addsToDailyLimit() {
        stubSettings();
        given(callHistoryRepository.sumDurationSeconds(memberId, TODAY_START, TODAY_END)).willReturn(1800L);
        stubBonusSeconds(600);

        CallLimitStatusResponse response = createService(NOON_KST).getTodayStatus(memberId);

        assertThat(response).isEqualTo(new CallLimitStatusResponse(1800, 600, 600, true));
    }

    @Test
    void checkStartable_monthRemainingBelowAllowed_capsAllowedSeconds() {
        stubSettings();
        stubUsedSeconds(0);
        stubMonth(900000, 899700);

        long allowedSeconds = createService(NOON_KST).checkStartable(memberId);

        assertThat(allowedSeconds).isEqualTo(300);
    }

    @Test
    void checkStartable_monthRemainingExactlyMinStart_allowed() {
        stubSettings();
        stubUsedSeconds(0);
        stubMonth(900000, 899940);

        long allowedSeconds = createService(NOON_KST).checkStartable(memberId);

        assertThat(allowedSeconds).isEqualTo(60);
    }

    @Test
    void checkStartable_monthRemainingBelowMinStart_throwsServiceLimitExceeded() {
        stubSettings();
        stubUsedSeconds(0);
        stubMonth(900000, 899941);

        assertThatThrownBy(() -> createService(NOON_KST).checkStartable(memberId))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.CALL_SERVICE_LIMIT_EXCEEDED));
    }

    @Test
    void checkStartable_monthLimitExhausted_throwsServiceLimitExceeded() {
        stubSettings();
        stubUsedSeconds(0);
        stubMonth(900000, 950000);

        assertThatThrownBy(() -> createService(NOON_KST).checkStartable(memberId))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.CALL_SERVICE_LIMIT_EXCEEDED));
    }

    @Test
    void checkStartable_bothLimitsInsufficient_personalLimitTakesPrecedence() {
        stubSettings();
        stubUsedSeconds(1741);

        // 개인 한도가 먼저 걸리므로 월 한도는 조회하지 않는다
        assertThatThrownBy(() -> createService(NOON_KST).checkStartable(memberId))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.CALL_LIMIT_INSUFFICIENT));
    }

    @Test
    void checkStartable_sessionLimitBelowMinStartButMonthEnough_allowed() {
        given(settingConfigService.getInt(SettingKey.CALL_MAX_SECONDS_PER_SESSION)).willReturn(30L);
        given(settingConfigService.getInt(SettingKey.CALL_MAX_SECONDS_PER_DAY)).willReturn(1800L);
        given(settingConfigService.getInt(SettingKey.CALL_MIN_START_SECONDS)).willReturn(60L);
        stubUsedSeconds(0);
        stubMonth(900000, 0);

        long allowedSeconds = createService(NOON_KST).checkStartable(memberId);

        assertThat(allowedSeconds).isEqualTo(30);
    }

    @Test
    void checkStartable_lastSecondOfMonth_queriesCurrentKstMonth() {
        stubSettings();
        // 2026-10-31T23:59:59 KST
        Instant monthLastSecond = Instant.parse("2026-10-31T14:59:59Z");
        given(callHistoryRepository.sumDurationSeconds(any(), any(), any())).willReturn(0L);
        given(callBonusRepository.sumActiveSeconds(memberId, LocalDate.of(2026, 10, 31))).willReturn(0L);
        given(settingConfigService.getInt(SettingKey.CALL_MAX_SECONDS_PER_MONTH_TOTAL)).willReturn(900000L);
        given(callHistoryRepository.sumDurationSecondsOfAllMembers(MONTH_START, MONTH_END)).willReturn(0L);

        createService(monthLastSecond).checkStartable(memberId);

        verify(callHistoryRepository).sumDurationSecondsOfAllMembers(MONTH_START, MONTH_END);
    }

    @Test
    void checkStartable_atKstMonthStart_queriesNextKstMonth() {
        stubSettings();
        // 2026-11-01T00:00:00 KST
        Instant nextMonthFirstSecond = Instant.parse("2026-10-31T15:00:00Z");
        Instant novemberEnd = Instant.parse("2026-11-30T15:00:00Z");
        given(callHistoryRepository.sumDurationSeconds(any(), any(), any())).willReturn(0L);
        given(callBonusRepository.sumActiveSeconds(memberId, LocalDate.of(2026, 11, 1))).willReturn(0L);
        given(settingConfigService.getInt(SettingKey.CALL_MAX_SECONDS_PER_MONTH_TOTAL)).willReturn(900000L);
        given(callHistoryRepository.sumDurationSecondsOfAllMembers(nextMonthFirstSecond, novemberEnd))
            .willReturn(0L);

        createService(nextMonthFirstSecond).checkStartable(memberId);

        verify(callHistoryRepository).sumDurationSecondsOfAllMembers(nextMonthFirstSecond, novemberEnd);
    }

}
