package kr.co.teeq.api.admin.application.service;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.TemporalAdjusters;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Stream;
import kr.co.teeq.api.admin.application.dto.response.AdminDashboardResponse;
import kr.co.teeq.api.admin.application.dto.response.AdminDashboardResponse.RecentBonus;
import kr.co.teeq.api.admin.application.dto.response.AdminDashboardResponse.RecentFeedback;
import kr.co.teeq.api.admin.application.dto.response.AdminDashboardResponse.RecentMember;
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
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 관리자 대시보드 홈 집계. 열 때마다 읽기 전용 쿼리로 계산하며 "오늘"·"이번 달"은 KST 기준이다.
 * 통화 횟수·시간은 통화 사용량 화면과 숫자가 같도록 {@link CallUsageService}를 재사용한다.
 */
@Service
@RequiredArgsConstructor
public class AdminDashboardService {

    private static final int DAILY_USAGE_DAYS = 14;
    private static final int RETURNING_WINDOW_DAYS = 7;
    private static final long RETURNING_MINIMUM_CALLS = 2;
    private static final int RECENT_ITEM_LIMIT = 5;
    private static final int FREE_TEXT_PREVIEW_LENGTH = 40;
    private static final String REQUIRED_FEEDBACK_KIND = "필수";
    private static final String DETAILED_FEEDBACK_KIND = "상세";
    private static final String EMAIL_MASK = "***";

    private final MemberRepository memberRepository;
    private final OnboardingSubmissionRepository onboardingSubmissionRepository;
    private final CallHistoryRepository callHistoryRepository;
    private final CallBonusRepository callBonusRepository;
    private final RequiredFeedbackRepository requiredFeedbackRepository;
    private final DetailedFeedbackRepository detailedFeedbackRepository;
    private final CallUsageService callUsageService;
    private final SettingConfigService settingConfigService;
    private final Clock clock;
    private final ZoneId koreaZoneId;

    @Transactional(readOnly = true)
    public AdminDashboardResponse getDashboard() {
        LocalDate today = LocalDate.now(clock.withZone(koreaZoneId));
        Instant todayStart = startOf(today);
        Instant tomorrowStart = startOf(today.plusDays(1));
        // 최근 7일(오늘 포함)
        Instant weekStart = startOf(today.minusDays(RETURNING_WINDOW_DAYS - 1));

        List<CallUsageResponse> dailyUsages = callUsageService.getUsages(
            CallUsageUnit.DAY, today.minusDays(DAILY_USAGE_DAYS - 1), today, null);
        CallUsageResponse todayUsage = dailyUsages.getLast();
        long monthUsedSeconds = callUsageService.getUsages(CallUsageUnit.MONTH, today, today, null)
            .getFirst().usedSeconds();
        long monthLimitSeconds = settingConfigService.getInt(SettingKey.CALL_MAX_SECONDS_PER_MONTH_TOTAL);
        LocalDate monthStart = today.withDayOfMonth(1);
        LocalDate monthEnd = today.with(TemporalAdjusters.lastDayOfMonth());

        return new AdminDashboardResponse(
            callHistoryRepository.countReturningMembers(weekStart, tomorrowStart, RETURNING_MINIMUM_CALLS),
            memberRepository.countByDeletedFalse(),
            memberRepository.countByCreatedAtGreaterThanEqualAndDeletedFalse(todayStart),
            todayUsage.callCount(),
            todayUsage.usedSeconds(),
            ratio(onboardingSubmissionRepository.countSignedUpMembersWithActiveSubmission(),
                memberRepository.countByDeletedFalse()),
            requiredFeedbackRepository.countByCreatedAtGreaterThanEqualAndCreatedAtLessThanAndDeletedFalse(
                weekStart, tomorrowStart),
            detailedFeedbackRepository.countByCreatedAtGreaterThanEqualAndCreatedAtLessThanAndDeletedFalse(
                weekStart, tomorrowStart),
            callBonusRepository.countActiveByBonusDateBetween(monthStart, monthEnd),
            callBonusRepository.sumActiveSecondsByBonusDateBetween(monthStart, monthEnd),
            dailyUsages,
            monthUsedSeconds,
            monthLimitSeconds,
            ratio(monthUsedSeconds, monthLimitSeconds),
            recentMembers(),
            recentFeedbacks(),
            recentBonuses());
    }

    private Instant startOf(LocalDate date) {
        return date.atStartOfDay(koreaZoneId).toInstant();
    }

    // 분모가 0 이하면 0으로 나누지 않고 0을 돌려준다
    private double ratio(long numerator, long denominator) {
        return denominator <= 0 ? 0.0 : (double) numerator / denominator;
    }

    private List<RecentMember> recentMembers() {
        return memberRepository.findTop5ByDeletedFalseOrderByCreatedAtDesc().stream()
            .map(member -> new RecentMember(maskEmail(member.getEmail()), member.getCreatedAt()))
            .toList();
    }

    // 필수·상세를 합쳐 생성 시각이 늦은 순으로 5건
    private List<RecentFeedback> recentFeedbacks() {
        Stream<RecentFeedback> requiredFeedbacks = requiredFeedbackRepository
            .findTop5ByDeletedFalseOrderByCreatedAtDesc().stream()
            .map(this::toRecentFeedback);
        Stream<RecentFeedback> detailedFeedbacks = detailedFeedbackRepository
            .findTop5ByDeletedFalseOrderByCreatedAtDesc().stream()
            .map(this::toRecentFeedback);
        return Stream.concat(requiredFeedbacks, detailedFeedbacks)
            .sorted(Comparator.comparing(RecentFeedback::createdAt).reversed())
            .limit(RECENT_ITEM_LIMIT)
            .toList();
    }

    private RecentFeedback toRecentFeedback(RequiredFeedback feedback) {
        return new RecentFeedback(REQUIRED_FEEDBACK_KIND, feedback.getRating(), feedback.getCreatedAt(), null);
    }

    private RecentFeedback toRecentFeedback(DetailedFeedback feedback) {
        return new RecentFeedback(DETAILED_FEEDBACK_KIND, null, feedback.getCreatedAt(),
            preview(feedback.getFreeText()));
    }

    private List<RecentBonus> recentBonuses() {
        return callBonusRepository.findTop5ByDeletedFalseOrderByCreatedAtDesc().stream()
            .map(bonus -> new RecentBonus(bonus.getBonusDate(), bonus.getSeconds(), bonus.getReason(),
                bonus.getCreatedAt()))
            .toList();
    }

    // 문자 단위(code point)로 앞 40자만 남긴다
    private String preview(String freeText) {
        if (freeText == null) {
            return null;
        }
        return freeText.codePoints()
            .limit(FREE_TEXT_PREVIEW_LENGTH)
            .collect(StringBuilder::new, StringBuilder::appendCodePoint, StringBuilder::append)
            .toString();
    }

    // 로컬 부분의 앞 1자만 남기고 가린다(예: minji@gmail.com → m***@gmail.com)
    private String maskEmail(String email) {
        int atIndex = email.indexOf('@');
        String localPart = atIndex < 0 ? email : email.substring(0, atIndex);
        String domainPart = atIndex < 0 ? "" : email.substring(atIndex);
        if (localPart.isEmpty()) {
            return EMAIL_MASK + domainPart;
        }
        return localPart.substring(0, localPart.offsetByCodePoints(0, 1)) + EMAIL_MASK + domainPart;
    }

}
