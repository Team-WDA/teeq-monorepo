package kr.co.teeq.api.admin.application.service;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.TreeSet;
import kr.co.teeq.api.admin.application.dto.response.AdminAiMetricsResponse;
import kr.co.teeq.api.admin.application.dto.response.AdminAiMetricsRow;
import kr.co.teeq.api.admin.application.dto.response.AdminAiSummaryResponse;
import kr.co.teeq.api.call.core.constant.AbnormalCallCriteria;
import kr.co.teeq.api.call.core.constant.CallUsageUnit;
import kr.co.teeq.api.call.core.port.AiCallMetrics;
import kr.co.teeq.api.call.core.port.AiCallMetricsPeriod;
import kr.co.teeq.api.call.core.port.AiCallMetricsPort;
import kr.co.teeq.api.call.core.port.AiCallMetricsTotals;
import kr.co.teeq.api.call.core.repository.CallHistoryRepository;
import kr.co.teeq.api.call.core.repository.CallHistoryRepository.AbnormalCallRow;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * AI 품질·비용 조회. AI 서버의 기간별 집계와 BE의 비정상 종료 건수를 기간으로 합친다.
 * AI 서버 호출 중에는 DB 트랜잭션을 열어 두지 않으므로 @Transactional을 붙이지 않는다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AdminAiMetricsService {

    // 타입 없는 null은 PostgreSQL에서 bytea로 바인딩돼 실패하므로 전체 기간은 고정 경계값으로 조회한다
    static final Instant UNBOUNDED_RANGE_START = Instant.EPOCH;
    static final Instant UNBOUNDED_RANGE_END_EXCLUSIVE = Instant.parse("2100-01-01T00:00:00Z");
    // AI가 보낸 기간 시작일의 허용 범위. 벗어나면 빈 기간 채우기가 수십만 번 돌 수 있어 이상한 응답으로 본다
    static final LocalDate AI_PERIOD_START_MINIMUM = LocalDate.of(2000, 1, 1);
    static final LocalDate AI_PERIOD_START_END_EXCLUSIVE = LocalDate.of(2100, 1, 1);

    private final AiCallMetricsPort aiCallMetricsPort;
    private final CallHistoryRepository callHistoryRepository;
    private final Clock clock;
    private final ZoneId koreaZoneId;

    public AdminAiMetricsResponse getMetrics(CallUsageUnit unit, LocalDate from, LocalDate to) {
        if (from != null && to != null && from.isAfter(to)) {
            throw new CustomException(ErrorCode.INVALID_REQUEST);
        }
        AiCallMetrics aiMetrics;
        try {
            aiMetrics = aiCallMetricsPort.find(from, to, unit);
        } catch (CustomException exception) {
            if (exception.getErrorCode() != ErrorCode.AI_SERVER_UNAVAILABLE) {
                throw exception;
            }
            log.warn("AI 서버 집계 조회 실패로 AI 지표 없이 표시합니다: {}", exception.getMessage());
            return unavailableResponse(unit, from, to);
        }
        if (hasPeriodOutOfRange(aiMetrics.periods())) {
            log.warn("AI 서버 집계의 기간 시작일이 허용 범위를 벗어나 AI 지표 없이 표시합니다");
            return unavailableResponse(unit, from, to);
        }
        Map<LocalDate, Long> abnormalCounts = findAbnormalCounts(unit, from, to);
        List<AdminAiMetricsRow> rows = mergeRows(unit, aiMetrics.periods(), abnormalCounts);
        long abnormalTotal = abnormalCounts.values().stream().mapToLong(Long::longValue).sum();
        return new AdminAiMetricsResponse(unit, from, to, false, rows, totalRow(aiMetrics.totals(), abnormalTotal));
    }

    // AI 서버를 한 번만 부르고(전체 기간·일별) 그 결과에서 오늘 행과 전체 합계를 고른다
    public AdminAiSummaryResponse getSummary() {
        AdminAiMetricsResponse metrics = getMetrics(CallUsageUnit.DAY, null, null);
        LocalDate today = LocalDate.now(clock.withZone(koreaZoneId));
        AdminAiMetricsRow todayRow = metrics.rows().stream()
            .filter(row -> today.equals(row.periodStart()))
            .findFirst()
            .orElseGet(() -> AdminAiMetricsRow.empty(today));
        return new AdminAiSummaryResponse(metrics.unavailable(), todayRow, metrics.total());
    }

    private AdminAiMetricsResponse unavailableResponse(CallUsageUnit unit, LocalDate from, LocalDate to) {
        return new AdminAiMetricsResponse(unit, from, to, true, List.of(), AdminAiMetricsRow.empty(null));
    }

    private boolean hasPeriodOutOfRange(List<AiCallMetricsPeriod> aiPeriods) {
        return aiPeriods.stream()
            .map(AiCallMetricsPeriod::periodStart)
            .anyMatch(periodStart -> periodStart.isBefore(AI_PERIOD_START_MINIMUM)
                || !periodStart.isBefore(AI_PERIOD_START_END_EXCLUSIVE));
    }

    // KST 하루 경계로 바꾼 범위의 기간별 비정상 종료 건수(기간 시작 날짜 → 건수)
    private Map<LocalDate, Long> findAbnormalCounts(CallUsageUnit unit, LocalDate from, LocalDate to) {
        Instant fromInclusive = from == null ? UNBOUNDED_RANGE_START : from.atStartOfDay(koreaZoneId).toInstant();
        Instant toExclusive = to == null
            ? UNBOUNDED_RANGE_END_EXCLUSIVE
            : to.plusDays(1).atStartOfDay(koreaZoneId).toInstant();
        List<AbnormalCallRow> abnormalRows = callHistoryRepository.aggregateAbnormal(unit.truncateField(),
            koreaZoneId.getId(), fromInclusive, toExclusive, AbnormalCallCriteria.statusNames(),
            AbnormalCallCriteria.endedEndReasonNames());
        Map<LocalDate, Long> abnormalCounts = new TreeMap<>();
        for (AbnormalCallRow abnormalRow : abnormalRows) {
            LocalDate periodStart = unit.alignToPeriodStart(LocalDate.parse(abnormalRow.getPeriodStart()));
            abnormalCounts.merge(periodStart, abnormalRow.getAbnormalCount(), Long::sum);
        }
        return abnormalCounts;
    }

    // AI 기간과 BE 기간을 합쳐 첫 기간부터 마지막 기간까지 빠짐없이 오름차순으로 만든다
    private List<AdminAiMetricsRow> mergeRows(CallUsageUnit unit, List<AiCallMetricsPeriod> aiPeriods,
        Map<LocalDate, Long> abnormalCounts) {
        TreeMap<LocalDate, AiCallMetricsPeriod> aiPeriodsByStart = new TreeMap<>();
        for (AiCallMetricsPeriod aiPeriod : aiPeriods) {
            aiPeriodsByStart.put(unit.alignToPeriodStart(aiPeriod.periodStart()), aiPeriod);
        }
        TreeSet<LocalDate> periodStarts = new TreeSet<>(aiPeriodsByStart.keySet());
        periodStarts.addAll(abnormalCounts.keySet());
        if (periodStarts.isEmpty()) {
            return List.of();
        }
        List<AdminAiMetricsRow> rows = new ArrayList<>();
        for (LocalDate periodStart = periodStarts.first(); !periodStart.isAfter(periodStarts.last());
            periodStart = unit.nextPeriodStart(periodStart)) {
            long abnormalCount = abnormalCounts.getOrDefault(periodStart, 0L);
            rows.add(periodRow(periodStart, aiPeriodsByStart.get(periodStart), abnormalCount));
        }
        return rows;
    }

    private AdminAiMetricsRow periodRow(LocalDate periodStart, AiCallMetricsPeriod aiPeriod, long abnormalCount) {
        // AI에 없는 기간(BE 비정상 종료만 있거나 빈 기간)은 AI 값을 0·null로 둔다
        if (aiPeriod == null) {
            return new AdminAiMetricsRow(periodStart, 0, 0, 0, null, null, BigDecimal.ZERO, abnormalCount);
        }
        return new AdminAiMetricsRow(periodStart, aiPeriod.callCount(), aiPeriod.measuredCallCount(),
            aiPeriod.turnCount(), aiPeriod.p50LatencyMillis(), aiPeriod.p95LatencyMillis(),
            aiPeriod.estimatedCostUsd(), abnormalCount);
    }

    private AdminAiMetricsRow totalRow(AiCallMetricsTotals totals, long abnormalTotal) {
        return new AdminAiMetricsRow(null, totals.callCount(), totals.measuredCallCount(), totals.turnCount(),
            totals.p50LatencyMillis(), totals.p95LatencyMillis(), totals.estimatedCostUsd(), abnormalTotal);
    }

}
