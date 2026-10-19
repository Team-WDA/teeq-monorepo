package kr.co.teeq.api.admin.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import kr.co.teeq.api.admin.application.dto.response.AdminDashboardResponse;
import kr.co.teeq.api.admin.application.dto.response.AdminDashboardResponse.RecentFeedback;
import kr.co.teeq.api.call.application.dto.response.CallUsageResponse;
import kr.co.teeq.api.call.application.service.CallUsageService;
import kr.co.teeq.api.call.core.constant.CallUsageUnit;
import kr.co.teeq.api.call.core.repository.CallBonusRepository;
import kr.co.teeq.api.call.core.repository.CallHistoryRepository;
import kr.co.teeq.api.feedback.core.entity.DetailedFeedback;
import kr.co.teeq.api.feedback.core.entity.RequiredFeedback;
import kr.co.teeq.api.feedback.core.repository.DetailedFeedbackRepository;
import kr.co.teeq.api.feedback.core.repository.RequiredFeedbackRepository;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.repository.MemberRepository;
import kr.co.teeq.api.onboarding.core.repository.OnboardingSubmissionRepository;
import kr.co.teeq.api.setting.application.service.SettingConfigService;
import kr.co.teeq.api.setting.core.constant.SettingKey;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class AdminDashboardServiceTest {

    private static final ZoneId KOREA = ZoneId.of("Asia/Seoul");
    // KST 2026-10-20 12:00
    private static final Instant NOW = Instant.parse("2026-10-20T03:00:00Z");
    private static final LocalDate TODAY = LocalDate.of(2026, 10, 20);
    private static final LocalDate FOURTEEN_DAYS_START = LocalDate.of(2026, 10, 7);

    @Mock
    private MemberRepository memberRepository;

    @Mock
    private OnboardingSubmissionRepository onboardingSubmissionRepository;

    @Mock
    private CallHistoryRepository callHistoryRepository;

    @Mock
    private CallBonusRepository callBonusRepository;

    @Mock
    private RequiredFeedbackRepository requiredFeedbackRepository;

    @Mock
    private DetailedFeedbackRepository detailedFeedbackRepository;

    @Mock
    private CallUsageService callUsageService;

    @Mock
    private SettingConfigService settingConfigService;

    private AdminDashboardService createService() {
        return new AdminDashboardService(memberRepository, onboardingSubmissionRepository, callHistoryRepository,
            callBonusRepository, requiredFeedbackRepository, detailedFeedbackRepository, callUsageService,
            settingConfigService, Clock.fixed(NOW, ZoneOffset.UTC), KOREA);
    }

    private static Instant kstStart(LocalDate date) {
        return date.atStartOfDay(KOREA).toInstant();
    }

    // 14일 일별 사용량(마지막 날 = 오늘)과 이번 달 사용량을 돌려주도록 한다
    private void givenUsages(long todayUsedSeconds, long todayCallCount, long monthUsedSeconds, long monthLimitSeconds) {
        List<CallUsageResponse> dailyUsages = new ArrayList<>();
        for (LocalDate date = FOURTEEN_DAYS_START; date.isBefore(TODAY); date = date.plusDays(1)) {
            dailyUsages.add(new CallUsageResponse(date, 0, 0));
        }
        dailyUsages.add(new CallUsageResponse(TODAY, todayUsedSeconds, todayCallCount));
        given(callUsageService.getUsages(eq(CallUsageUnit.DAY), any(), any(), isNull())).willReturn(dailyUsages);
        given(callUsageService.getUsages(eq(CallUsageUnit.MONTH), any(), any(), isNull()))
            .willReturn(List.of(new CallUsageResponse(LocalDate.of(2026, 10, 1), monthUsedSeconds, 0)));
        given(settingConfigService.getInt(SettingKey.CALL_MAX_SECONDS_PER_MONTH_TOTAL)).willReturn(monthLimitSeconds);
    }

    @Test
    void getDashboard_emptyDatabase_returnsZerosWithoutError() {
        givenUsages(0, 0, 0, 900_000);

        AdminDashboardResponse response = createService().getDashboard();

        assertThat(response.weeklyReturningMembers()).isZero();
        assertThat(response.totalMembers()).isZero();
        assertThat(response.todayJoinedMembers()).isZero();
        assertThat(response.todayCallCount()).isZero();
        assertThat(response.todayCallSeconds()).isZero();
        // 분모가 0이어도 0으로 나누지 않는다
        assertThat(response.onboardingCompletionRate()).isEqualTo(0.0);
        assertThat(response.recentFeedbackRequiredCount()).isZero();
        assertThat(response.recentFeedbackDetailedCount()).isZero();
        assertThat(response.monthBonusCount()).isZero();
        assertThat(response.monthBonusSeconds()).isZero();
        assertThat(response.monthUsedSeconds()).isZero();
        assertThat(response.monthLimitRate()).isEqualTo(0.0);
        assertThat(response.dailyUsages()).hasSize(14);
        assertThat(response.recentMembers()).isEmpty();
        assertThat(response.recentFeedbacks()).isEmpty();
        assertThat(response.recentBonuses()).isEmpty();
    }

    @Test
    void getDashboard_monthLimitRate_notCappedInResponseButFlagged() {
        givenUsages(0, 0, 1_000_000, 900_000);

        AdminDashboardResponse response = createService().getDashboard();

        assertThat(response.monthUsedSeconds()).isEqualTo(1_000_000);
        assertThat(response.monthLimitSeconds()).isEqualTo(900_000);
        assertThat(response.monthLimitRate()).isCloseTo(1.111, within(0.001));
        // 응답 값은 보정하지 않고, 막대 길이만 100%에서 멈춘다
        assertThat(response.monthLimitExceeded()).isTrue();
        assertThat(response.monthLimitGaugePercent()).isEqualTo(100);
    }

    @Test
    void getDashboard_onboardingCompletionRate() {
        givenUsages(0, 0, 0, 900_000);
        given(memberRepository.countByNicknameIsNotNullAndDeletedFalse()).willReturn(100L);
        given(onboardingSubmissionRepository.countSignedUpMembersWithActiveSubmission()).willReturn(82L);

        AdminDashboardResponse response = createService().getDashboard();

        assertThat(response.onboardingCompletionRate()).isEqualTo(0.82);
    }

    @Test
    void getDashboard_usesKoreaTodayBoundaries() {
        givenUsages(1_800, 3, 50_000, 900_000);
        given(memberRepository.countByDeletedFalse()).willReturn(1_942L);
        given(memberRepository.countByCreatedAtGreaterThanEqualAndDeletedFalse(kstStart(TODAY))).willReturn(17L);

        AdminDashboardResponse response = createService().getDashboard();

        verify(callUsageService).getUsages(CallUsageUnit.DAY, FOURTEEN_DAYS_START, TODAY, null);
        verify(callUsageService).getUsages(CallUsageUnit.MONTH, TODAY, TODAY, null);
        assertThat(response.todayCallCount()).isEqualTo(3);
        assertThat(response.todayCallSeconds()).isEqualTo(1_800);
        assertThat(response.totalMembers()).isEqualTo(1_942);
        // 오늘 가입은 KST 자정(2026-10-20T00:00+09:00) 이후다
        assertThat(response.todayJoinedMembers()).isEqualTo(17);
        assertThat(response.monthUsedSeconds()).isEqualTo(50_000);
    }

    @Test
    void getDashboard_weeklyReturningMembers_usesLastSevenDaysIncludingToday() {
        givenUsages(0, 0, 0, 900_000);
        Instant weekStart = Instant.parse("2026-10-13T15:00:00Z");
        Instant tomorrowStart = Instant.parse("2026-10-20T15:00:00Z");
        given(callHistoryRepository.countReturningMembers(weekStart, tomorrowStart, 2)).willReturn(128L);
        given(requiredFeedbackRepository.countByCreatedAtGreaterThanEqualAndCreatedAtLessThanAndDeletedFalse(
            weekStart, tomorrowStart)).willReturn(38L);
        given(detailedFeedbackRepository.countByCreatedAtGreaterThanEqualAndCreatedAtLessThanAndDeletedFalse(
            weekStart, tomorrowStart)).willReturn(8L);

        AdminDashboardResponse response = createService().getDashboard();

        assertThat(response.weeklyReturningMembers()).isEqualTo(128);
        assertThat(response.recentFeedbackRequiredCount()).isEqualTo(38);
        assertThat(response.recentFeedbackDetailedCount()).isEqualTo(8);
    }

    @Test
    void getDashboard_monthBonus_usesCurrentKoreaMonthBonusDates() {
        givenUsages(0, 0, 0, 900_000);
        LocalDate monthStart = LocalDate.of(2026, 10, 1);
        LocalDate monthEnd = LocalDate.of(2026, 10, 31);
        given(callBonusRepository.countActiveByBonusDateBetween(monthStart, monthEnd)).willReturn(12L);
        given(callBonusRepository.sumActiveSecondsByBonusDateBetween(monthStart, monthEnd)).willReturn(6_000L);

        AdminDashboardResponse response = createService().getDashboard();

        assertThat(response.monthBonusCount()).isEqualTo(12);
        assertThat(response.monthBonusSeconds()).isEqualTo(6_000);
    }

    @Test
    void getDashboard_recentMembers_masksEmailExceptFirstCharacter() {
        givenUsages(0, 0, 0, 900_000);
        Member member = mock(Member.class);
        given(member.getEmail()).willReturn("minji@gmail.com");
        given(member.getCreatedAt()).willReturn(NOW);
        given(memberRepository.findTop5ByDeletedFalseOrderByCreatedAtDesc()).willReturn(List.of(member));

        AdminDashboardResponse response = createService().getDashboard();

        assertThat(response.recentMembers()).hasSize(1);
        assertThat(response.recentMembers().getFirst().maskedEmail()).isEqualTo("m***@gmail.com");
        assertThat(response.recentMembers().getFirst().joinedAt()).isEqualTo(NOW);
    }

    @Test
    void getDashboard_recentFeedbacks_mergesBothKindsNewestFiveWithFreeTextPreview() {
        givenUsages(0, 0, 0, 900_000);
        List<RequiredFeedback> requiredFeedbacks = new ArrayList<>();
        for (int minutesAgo = 1; minutesAgo <= 9; minutesAgo += 2) {
            requiredFeedbacks.add(requiredFeedback(4, NOW.minusSeconds(minutesAgo * 60L)));
        }
        String longFreeText = "가".repeat(45);
        List<DetailedFeedback> detailedFeedbacks = List.of(
            detailedFeedback(longFreeText, NOW.minusSeconds(2 * 60L)),
            detailedFeedback(null, NOW.minusSeconds(4 * 60L)));
        given(requiredFeedbackRepository.findTop5ByDeletedFalseOrderByCreatedAtDesc()).willReturn(requiredFeedbacks);
        given(detailedFeedbackRepository.findTop5ByDeletedFalseOrderByCreatedAtDesc()).willReturn(detailedFeedbacks);

        List<RecentFeedback> recentFeedbacks = createService().getDashboard().recentFeedbacks();

        // 1분(필수), 2분(상세), 3분(필수), 4분(상세), 5분(필수) 전
        assertThat(recentFeedbacks).extracting(RecentFeedback::kind)
            .containsExactly("필수", "상세", "필수", "상세", "필수");
        assertThat(recentFeedbacks.get(0).rating()).isEqualTo(4);
        assertThat(recentFeedbacks.get(1).rating()).isNull();
        assertThat(recentFeedbacks.get(1).freeTextPreview()).isEqualTo("가".repeat(40));
        assertThat(recentFeedbacks.get(3).freeTextPreview()).isNull();
        assertThat(recentFeedbacks.get(0).createdAt()).isEqualTo(NOW.minusSeconds(60));
    }

    private RequiredFeedback requiredFeedback(int rating, Instant createdAt) {
        RequiredFeedback feedback = mock(RequiredFeedback.class);
        given(feedback.getRating()).willReturn(rating);
        given(feedback.getCreatedAt()).willReturn(createdAt);
        return feedback;
    }

    private DetailedFeedback detailedFeedback(String freeText, Instant createdAt) {
        DetailedFeedback feedback = mock(DetailedFeedback.class);
        given(feedback.getFreeText()).willReturn(freeText);
        given(feedback.getCreatedAt()).willReturn(createdAt);
        return feedback;
    }

}
