package kr.co.teeq.api.admin.application.dto.response;

import java.time.LocalDate;
import java.util.List;
import java.util.Objects;
import kr.co.teeq.api.call.core.constant.CallUsageUnit;

/**
 * AI 품질·비용 화면의 기간별 행과 합계. from/to가 null이면 그 방향은 제한 없음(전체)이다.
 * unavailable이면 AI 서버가 응답하지 못한 것이며 rows는 비어 있고 total은 0이다.
 * maxP95LatencyMillis는 막대 높이 기준값으로, 넘긴 값과 관계없이 생성할 때 rows에서 한 번 계산한다(값이 없으면 0).
 */
public record AdminAiMetricsResponse(
    CallUsageUnit unit,
    LocalDate from,
    LocalDate to,
    boolean unavailable,
    List<AdminAiMetricsRow> rows,
    AdminAiMetricsRow total,
    int maxP95LatencyMillis
) {

    private static final int FULL_PERCENT = 100;

    public AdminAiMetricsResponse {
        rows = List.copyOf(rows);
        maxP95LatencyMillis = maxP95LatencyMillis(rows);
    }

    public AdminAiMetricsResponse(CallUsageUnit unit, LocalDate from, LocalDate to, boolean unavailable,
        List<AdminAiMetricsRow> rows, AdminAiMetricsRow total) {
        this(unit, from, to, unavailable, rows, total, 0);
    }

    // 행 중 가장 큰 p95를 100%로 둔 막대 높이. 최대값이 0이거나 p95가 null이면 0%
    public int barHeightPercent(AdminAiMetricsRow row) {
        if (maxP95LatencyMillis == 0 || row.p95LatencyMillis() == null) {
            return 0;
        }
        return (int) Math.round((double) row.p95LatencyMillis() * FULL_PERCENT / maxP95LatencyMillis);
    }

    private static int maxP95LatencyMillis(List<AdminAiMetricsRow> rows) {
        return rows.stream()
            .map(AdminAiMetricsRow::p95LatencyMillis)
            .filter(Objects::nonNull)
            .mapToInt(Integer::intValue)
            .max()
            .orElse(0);
    }

}
