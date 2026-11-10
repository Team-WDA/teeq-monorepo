package kr.co.teeq.api.call.infrastructure.adapter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import kr.co.teeq.api.call.core.constant.CallUsageUnit;
import kr.co.teeq.api.call.core.port.AiCallMetrics;
import kr.co.teeq.api.call.core.port.AiCallMetricsPeriod;
import kr.co.teeq.api.call.core.port.AiCallMetricsPort;
import kr.co.teeq.api.call.core.port.AiCallMetricsTotals;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.common.infrastructure.properties.AiServerProperties;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Slf4j
@Component
public class AiServerCallMetricsAdapter implements AiCallMetricsPort {

    private static final String PERIODS_FIELD = "periods";
    private static final String TOTALS_FIELD = "totals";
    private static final String PERIOD_START_FIELD = "periodStart";
    private static final String CALL_COUNT_FIELD = "callCount";
    private static final String MEASURED_CALL_COUNT_FIELD = "measuredCallCount";
    private static final String TURN_COUNT_FIELD = "turnCount";
    private static final String P50_LATENCY_FIELD = "p50LatencyMillis";
    private static final String P95_LATENCY_FIELD = "p95LatencyMillis";
    private static final String ESTIMATED_COST_FIELD = "estimatedCostUsd";

    private final RestClient restClient;
    private final AiServerProperties properties;

    public AiServerCallMetricsAdapter(
        @Qualifier("aiMetricsRestClient") RestClient aiMetricsRestClient,
        AiServerProperties properties
    ) {
        this.restClient = aiMetricsRestClient;
        this.properties = properties;
    }

    // 재시도하지 않는다. 이 엔드포인트는 엄격하게 읽어 어떤 실패도 AI_SERVER_UNAVAILABLE로 바꾼다
    @Override
    public AiCallMetrics find(LocalDate from, LocalDate to, CallUsageUnit unit) {
        Map<String, Object> responseBody;
        try {
            responseBody = restClient.get()
                .uri(uriBuilder -> {
                    uriBuilder.path("/metrics/calls");
                    if (from != null) {
                        uriBuilder.queryParam("from", from);
                    }
                    if (to != null) {
                        uriBuilder.queryParam("to", to);
                    }
                    return uriBuilder.queryParam("unit", unit.name()).build();
                })
                .header(properties.authHeaderName(), properties.authHeaderValue())
                .retrieve()
                .body(new ParameterizedTypeReference<Map<String, Object>>() {
                });
        } catch (RestClientException exception) {
            throw new CustomException(ErrorCode.AI_SERVER_UNAVAILABLE, exception);
        }
        if (responseBody == null) {
            throw invalidResponse("응답 본문이 비어 있습니다");
        }
        return new AiCallMetrics(readPeriods(responseBody.get(PERIODS_FIELD)),
            readTotals(responseBody.get(TOTALS_FIELD)));
    }

    private List<AiCallMetricsPeriod> readPeriods(Object rawPeriods) {
        if (!(rawPeriods instanceof List<?> rawPeriodList)) {
            throw invalidResponse(PERIODS_FIELD + "가 없거나 배열이 아닙니다");
        }
        List<AiCallMetricsPeriod> periods = new ArrayList<>();
        for (Object rawPeriod : rawPeriodList) {
            if (!(rawPeriod instanceof Map<?, ?> period)) {
                throw invalidResponse(PERIODS_FIELD + "의 항목이 객체가 아닙니다");
            }
            periods.add(new AiCallMetricsPeriod(readPeriodStart(period.get(PERIOD_START_FIELD)),
                readCount(period.get(CALL_COUNT_FIELD), CALL_COUNT_FIELD),
                readCount(period.get(MEASURED_CALL_COUNT_FIELD), MEASURED_CALL_COUNT_FIELD),
                readCount(period.get(TURN_COUNT_FIELD), TURN_COUNT_FIELD), readMillis(period.get(P50_LATENCY_FIELD)),
                readMillis(period.get(P95_LATENCY_FIELD)), readCost(period.get(ESTIMATED_COST_FIELD))));
        }
        return periods;
    }

    private AiCallMetricsTotals readTotals(Object rawTotals) {
        if (!(rawTotals instanceof Map<?, ?> totals)) {
            throw invalidResponse(TOTALS_FIELD + "가 없거나 객체가 아닙니다");
        }
        return new AiCallMetricsTotals(readCount(totals.get(CALL_COUNT_FIELD), CALL_COUNT_FIELD),
            readCount(totals.get(MEASURED_CALL_COUNT_FIELD), MEASURED_CALL_COUNT_FIELD),
            readCount(totals.get(TURN_COUNT_FIELD), TURN_COUNT_FIELD),
            readMillis(totals.get(P50_LATENCY_FIELD)), readMillis(totals.get(P95_LATENCY_FIELD)),
            readCost(totals.get(ESTIMATED_COST_FIELD)));
    }

    private LocalDate readPeriodStart(Object rawPeriodStart) {
        if (!(rawPeriodStart instanceof String periodStart)) {
            throw invalidResponse(PERIOD_START_FIELD + "가 없거나 문자열이 아닙니다");
        }
        try {
            return LocalDate.parse(periodStart);
        } catch (DateTimeParseException exception) {
            throw invalidResponse(PERIOD_START_FIELD + "가 날짜 형식이 아닙니다");
        }
    }

    private long readCount(Object rawCount, String fieldName) {
        if (!(rawCount instanceof Number number)) {
            throw invalidResponse(fieldName + "가 없거나 숫자가 아닙니다");
        }
        return number.longValue();
    }

    private Integer readMillis(Object rawMillis) {
        return rawMillis instanceof Number number ? number.intValue() : null;
    }

    // 부동소수점 오차를 피하려고 숫자의 문자열 표현으로 BigDecimal을 만든다
    private BigDecimal readCost(Object rawCost) {
        if (!(rawCost instanceof Number number)) {
            throw invalidResponse(ESTIMATED_COST_FIELD + "가 없거나 숫자가 아닙니다");
        }
        return new BigDecimal(number.toString());
    }

    private CustomException invalidResponse(String reason) {
        log.error("AI 서버 집계 응답이 계약에 맞지 않습니다: {}", reason);
        return new CustomException(ErrorCode.AI_SERVER_UNAVAILABLE);
    }

}
