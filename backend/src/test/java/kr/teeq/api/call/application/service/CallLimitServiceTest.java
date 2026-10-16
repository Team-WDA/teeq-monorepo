package kr.teeq.api.call.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verify;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.UUID;
import kr.teeq.api.call.application.dto.response.CallLimitStatusResponse;
import kr.teeq.api.call.core.repository.CallHistoryRepository;
import kr.teeq.api.common.core.exception.CustomException;
import kr.teeq.api.common.core.exception.ErrorCode;
import kr.teeq.api.member.core.entity.Member;
import kr.teeq.api.member.core.repository.MemberRepository;
import kr.teeq.api.setting.application.service.SettingConfigService;
import kr.teeq.api.setting.core.constant.SettingKey;
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

    private final UUID memberId = UUID.randomUUID();

    @Mock
    private CallHistoryRepository callHistoryRepository;

    @Mock
    private MemberRepository memberRepository;

    @Mock
    private SettingConfigService settingConfigService;

    @Mock
    private Member member;

    private CallLimitService createService(Instant now) {
        return new CallLimitService(callHistoryRepository, memberRepository, settingConfigService,
            Clock.fixed(now, ZoneOffset.UTC), KOREA_ZONE_ID);
    }

    private void stubSettings() {
        given(settingConfigService.getInt(SettingKey.CALL_MAX_SECONDS_PER_SESSION)).willReturn(1200L);
        given(settingConfigService.getInt(SettingKey.CALL_MAX_SECONDS_PER_DAY)).willReturn(1800L);
        given(settingConfigService.getInt(SettingKey.CALL_MIN_START_SECONDS)).willReturn(60L);
    }

    private void stubUsedSeconds(long usedSeconds) {
        given(callHistoryRepository.sumDurationSeconds(memberId, TODAY_START, TODAY_END)).willReturn(usedSeconds);
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

        createService(Instant.parse("2026-10-16T15:00:00Z")).getTodayStatus(memberId);

        verify(callHistoryRepository).sumDurationSeconds(memberId, nextDayStart, nextDayEnd);
    }

    @Test
    void checkStartable_enoughTime_returnsAllowedSeconds() {
        given(memberRepository.findByIdAndDeletedFalse(memberId)).willReturn(Optional.of(member));
        stubSettings();
        stubUsedSeconds(1500);

        long allowedSeconds = createService(NOON_KST).checkStartable(memberId);

        assertThat(allowedSeconds).isEqualTo(300);
    }

    @Test
    void checkStartable_insufficient_throwsCallLimitInsufficient() {
        given(memberRepository.findByIdAndDeletedFalse(memberId)).willReturn(Optional.of(member));
        stubSettings();
        stubUsedSeconds(1741);

        assertThatThrownBy(() -> createService(NOON_KST).checkStartable(memberId))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.CALL_LIMIT_INSUFFICIENT));
    }

    @Test
    void checkStartable_unknownMember_throwsMemberNotFound() {
        given(memberRepository.findByIdAndDeletedFalse(memberId)).willReturn(Optional.empty());

        assertThatThrownBy(() -> createService(NOON_KST).checkStartable(memberId))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.MEMBER_NOT_FOUND));
    }

}
