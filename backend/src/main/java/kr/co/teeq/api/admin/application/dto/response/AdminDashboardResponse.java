package kr.co.teeq.api.admin.application.dto.response;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import kr.co.teeq.api.call.application.dto.response.CallUsageResponse;

/**
 * 관리자 대시보드 홈 집계. "오늘"과 "이번 달"은 KST 기준이다.
 * 한도 소진률은 보정하지 않은 실제 비율이며, 막대 길이(퍼센트)만 화면용으로 100%에서 멈춘다.
 */
public record AdminDashboardResponse(
    long weeklyReturningMembers,
    long totalMembers,
    long todayJoinedMembers,
    long todayCallCount,
    long todayCallSeconds,
    double onboardingCompletionRate,
    long recentFeedbackRequiredCount,
    long recentFeedbackDetailedCount,
    long monthBonusCount,
    long monthBonusSeconds,
    List<CallUsageResponse> dailyUsages,
    long monthUsedSeconds,
    long monthLimitSeconds,
    double monthLimitRate,
    List<RecentMember> recentMembers,
    List<RecentFeedback> recentFeedbacks,
    List<RecentBonus> recentBonuses
) {

    private static final int FULL_PERCENT = 100;

    public AdminDashboardResponse {
        dailyUsages = List.copyOf(dailyUsages);
        recentMembers = List.copyOf(recentMembers);
        recentFeedbacks = List.copyOf(recentFeedbacks);
        recentBonuses = List.copyOf(recentBonuses);
    }

    public long recentFeedbackTotalCount() {
        return recentFeedbackRequiredCount + recentFeedbackDetailedCount;
    }

    public long onboardingCompletionPercent() {
        return Math.round(onboardingCompletionRate * FULL_PERCENT);
    }

    // 실제 소진률(100% 초과 가능)
    public long monthLimitPercent() {
        return Math.round(monthLimitRate * FULL_PERCENT);
    }

    public boolean monthLimitExceeded() {
        return monthLimitRate > 1.0;
    }

    // 게이지 막대 길이. 100%를 넘으면 100%에서 멈춘다
    public long monthLimitGaugePercent() {
        return Math.min(FULL_PERCENT, monthLimitPercent());
    }

    // 14일 중 가장 긴 날을 100%로 둔 막대 높이. 통화가 없으면 0%
    public long barHeightPercent(CallUsageResponse usage) {
        long maxUsedSeconds = dailyUsages.stream().mapToLong(CallUsageResponse::usedSeconds).max().orElse(0);
        if (maxUsedSeconds == 0) {
            return 0;
        }
        return Math.round((double) usage.usedSeconds() * FULL_PERCENT / maxUsedSeconds);
    }

    // 최근 가입 회원. 이메일은 앞 1자만 남기고 가린다
    public record RecentMember(String maskedEmail, Instant joinedAt) {

    }

    // 최근 피드백. kind는 "필수"/"상세", rating은 필수만, freeTextPreview는 상세의 자유 입력 앞부분
    public record RecentFeedback(String kind, Integer rating, Instant createdAt, String freeTextPreview) {

    }

    // 최근 부여된(취소되지 않은) 보너스
    public record RecentBonus(LocalDate bonusDate, int seconds, String reason, Instant grantedAt) {

    }

}
