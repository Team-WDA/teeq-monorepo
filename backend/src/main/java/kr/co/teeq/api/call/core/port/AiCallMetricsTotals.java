package kr.co.teeq.api.call.core.port;

import java.math.BigDecimal;

// 기간별 값의 평균이 아니라 선택 범위 전체로 따로 계산된 값이다
public record AiCallMetricsTotals(
    long callCount,
    long measuredCallCount,
    long turnCount,
    Integer p50LatencyMillis,
    Integer p95LatencyMillis,
    BigDecimal estimatedCostUsd
) {

}
