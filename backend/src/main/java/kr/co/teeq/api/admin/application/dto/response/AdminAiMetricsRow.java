package kr.co.teeq.api.admin.application.dto.response;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * AI 품질·비용의 한 기간(또는 합계) 행. AI 집계 값과 BE 비정상 종료 건수를 함께 담는다.
 * 지연은 표본이 없으면 null이고, 합계 행은 periodStart가 null이다.
 */
public record AdminAiMetricsRow(
    LocalDate periodStart,
    long callCount,
    long measuredCallCount,
    long turnCount,
    Integer p50LatencyMillis,
    Integer p95LatencyMillis,
    BigDecimal estimatedCostUsd,
    long abnormalCallCount
) {

    // 값이 없는 기간(카운트 0, 지연 null, 비용 0)
    public static AdminAiMetricsRow empty(LocalDate periodStart) {
        return new AdminAiMetricsRow(periodStart, 0, 0, 0, null, null, BigDecimal.ZERO, 0);
    }

}
