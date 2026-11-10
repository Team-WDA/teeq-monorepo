package kr.co.teeq.api.call.core.port;

import java.math.BigDecimal;
import java.time.LocalDate;

// 지연은 표본이 없으면 null이다
public record AiCallMetricsPeriod(
    LocalDate periodStart,
    long callCount,
    long measuredCallCount,
    long turnCount,
    Integer p50LatencyMillis,
    Integer p95LatencyMillis,
    BigDecimal estimatedCostUsd
) {

}
