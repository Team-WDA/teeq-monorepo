package kr.co.teeq.api.call.core.port;

import java.util.List;

// AI 서버가 돌려준 기간별 집계와 선택 범위 전체 합계
public record AiCallMetrics(List<AiCallMetricsPeriod> periods, AiCallMetricsTotals totals) {

    public AiCallMetrics {
        periods = List.copyOf(periods);
    }

}
