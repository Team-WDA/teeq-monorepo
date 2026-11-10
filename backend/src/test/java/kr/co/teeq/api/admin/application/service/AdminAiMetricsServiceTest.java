package kr.co.teeq.api.admin.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.List;
import kr.co.teeq.api.admin.application.dto.response.AdminAiMetricsResponse;
import kr.co.teeq.api.admin.application.dto.response.AdminAiMetricsRow;
import kr.co.teeq.api.admin.application.dto.response.AdminAiSummaryResponse;
import kr.co.teeq.api.call.core.constant.CallUsageUnit;
import kr.co.teeq.api.call.core.port.AiCallMetrics;
import kr.co.teeq.api.call.core.port.AiCallMetricsPeriod;
import kr.co.teeq.api.call.core.port.AiCallMetricsPort;
import kr.co.teeq.api.call.core.port.AiCallMetricsTotals;
import kr.co.teeq.api.call.core.repository.CallHistoryRepository;
import kr.co.teeq.api.call.core.repository.CallHistoryRepository.AbnormalCallRow;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class AdminAiMetricsServiceTest {

    private static final ZoneId KOREA_ZONE_ID = ZoneId.of("Asia/Seoul");
    private static final Clock FIXED_CLOCK = Clock.fixed(Instant.parse("2026-11-10T03:00:00Z"), ZoneOffset.UTC);
    private static final AiCallMetricsTotals EMPTY_TOTALS = new AiCallMetricsTotals(0, 0, 0, null, null,
        BigDecimal.ZERO);

    @Mock
    private AiCallMetricsPort aiCallMetricsPort;
    @Mock
    private CallHistoryRepository callHistoryRepository;

    private AdminAiMetricsService service;

    @BeforeEach
    void setUp() {
        service = new AdminAiMetricsService(aiCallMetricsPort, callHistoryRepository, FIXED_CLOCK, KOREA_ZONE_ID);
    }

    @Test
    void 기간_행에_AI_값과_비정상_종료를_합친다() {
        givenAi(CallUsageUnit.DAY, List.of(period("2026-11-02", 4, 810, 1740, "0.31")), EMPTY_TOTALS);
        givenAbnormal(List.of(new TestAbnormalRow("2026-11-02", 1)));

        AdminAiMetricsResponse response = service.getMetrics(CallUsageUnit.DAY, null, null);

        assertThat(response.unavailable()).isFalse();
        assertThat(response.rows()).hasSize(1);
        AdminAiMetricsRow row = response.rows().getFirst();
        assertThat(row.periodStart()).isEqualTo(LocalDate.parse("2026-11-02"));
        assertThat(row.callCount()).isEqualTo(4);
        assertThat(row.measuredCallCount()).isEqualTo(4);
        assertThat(row.turnCount()).isEqualTo(96);
        assertThat(row.p50LatencyMillis()).isEqualTo(810);
        assertThat(row.p95LatencyMillis()).isEqualTo(1740);
        assertThat(row.estimatedCostUsd()).isEqualByComparingTo("0.31");
        assertThat(row.abnormalCallCount()).isEqualTo(1);
    }

    @Test
    void BE에만_있는_기간도_행으로_나타난다() {
        givenAi(CallUsageUnit.DAY, List.of(period("2026-11-02", 4, 810, 1740, "0.31")), EMPTY_TOTALS);
        givenAbnormal(List.of(new TestAbnormalRow("2026-11-03", 2)));

        AdminAiMetricsResponse response = service.getMetrics(CallUsageUnit.DAY, null, null);

        assertThat(response.rows()).extracting(AdminAiMetricsRow::periodStart)
            .containsExactly(LocalDate.parse("2026-11-02"), LocalDate.parse("2026-11-03"));
        AdminAiMetricsRow beOnlyRow = response.rows().get(1);
        assertThat(beOnlyRow.callCount()).isZero();
        assertThat(beOnlyRow.measuredCallCount()).isZero();
        assertThat(beOnlyRow.turnCount()).isZero();
        assertThat(beOnlyRow.p50LatencyMillis()).isNull();
        assertThat(beOnlyRow.p95LatencyMillis()).isNull();
        assertThat(beOnlyRow.estimatedCostUsd()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(beOnlyRow.abnormalCallCount()).isEqualTo(2);
    }

    @Test
    void 빠진_기간은_빈_행으로_채운다() {
        givenAi(CallUsageUnit.DAY, List.of(
            period("2026-11-01", 1, 700, 900, "0.10"),
            period("2026-11-04", 2, 800, 1000, "0.20")), EMPTY_TOTALS);
        givenAbnormal(List.of());

        AdminAiMetricsResponse response = service.getMetrics(CallUsageUnit.DAY, null, null);

        assertThat(response.rows()).extracting(AdminAiMetricsRow::periodStart).containsExactly(
            LocalDate.parse("2026-11-01"), LocalDate.parse("2026-11-02"),
            LocalDate.parse("2026-11-03"), LocalDate.parse("2026-11-04"));
        AdminAiMetricsRow filledRow = response.rows().get(1);
        assertThat(filledRow.callCount()).isZero();
        assertThat(filledRow.estimatedCostUsd()).isEqualTo(BigDecimal.ZERO);
        assertThat(filledRow.p50LatencyMillis()).isNull();
        assertThat(filledRow.p95LatencyMillis()).isNull();
        assertThat(filledRow.abnormalCallCount()).isZero();
    }

    @Test
    void 월_단위는_달의_1일로_맞추고_채운다() {
        givenAi(CallUsageUnit.MONTH, List.of(
            period("2026-09-01", 1, 700, 900, "0.10"),
            period("2026-11-01", 2, 800, 1000, "0.20")), EMPTY_TOTALS);
        givenAbnormal(List.of(new TestAbnormalRow("2026-10-01", 3)));

        AdminAiMetricsResponse response = service.getMetrics(CallUsageUnit.MONTH, null, null);

        assertThat(response.rows()).extracting(AdminAiMetricsRow::periodStart).containsExactly(
            LocalDate.parse("2026-09-01"), LocalDate.parse("2026-10-01"), LocalDate.parse("2026-11-01"));
        assertThat(response.rows().get(1).abnormalCallCount()).isEqualTo(3);
        verify(callHistoryRepository).aggregateAbnormal(eq("month"), eq("Asia/Seoul"), any(), any(), anyList(),
            anyList());
    }

    @Test
    void 월_단위에서_1일이_아닌_기간은_달의_1일로_합친다() {
        givenAi(CallUsageUnit.MONTH, List.of(period("2026-11-05", 2, 800, 1000, "0.20")), EMPTY_TOTALS);
        givenAbnormal(List.of(new TestAbnormalRow("2026-11-01", 1)));

        AdminAiMetricsResponse response = service.getMetrics(CallUsageUnit.MONTH, null, null);

        assertThat(response.rows()).hasSize(1);
        assertThat(response.rows().getFirst().periodStart()).isEqualTo(LocalDate.parse("2026-11-01"));
        assertThat(response.rows().getFirst().callCount()).isEqualTo(2);
        assertThat(response.rows().getFirst().abnormalCallCount()).isEqualTo(1);
    }

    @Test
    void 전체_기간이면_BE_조회_범위가_고정_경계값이다() {
        givenAi(CallUsageUnit.DAY, List.of(), EMPTY_TOTALS);
        givenAbnormal(List.of());

        service.getMetrics(CallUsageUnit.DAY, null, null);

        ArgumentCaptor<Instant> fromCaptor = ArgumentCaptor.forClass(Instant.class);
        ArgumentCaptor<Instant> toCaptor = ArgumentCaptor.forClass(Instant.class);
        verify(callHistoryRepository).aggregateAbnormal(eq("day"), eq("Asia/Seoul"), fromCaptor.capture(),
            toCaptor.capture(), eq(List.of("FAILED", "EXPIRED")), eq(List.of("AGENT_ERROR", "DISPATCH_FAILED")));
        assertThat(fromCaptor.getValue()).isEqualTo(Instant.EPOCH);
        assertThat(toCaptor.getValue()).isEqualTo(Instant.parse("2100-01-01T00:00:00Z"));
        assertThat(AdminAiMetricsService.UNBOUNDED_RANGE_START).isEqualTo(Instant.EPOCH);
        assertThat(AdminAiMetricsService.UNBOUNDED_RANGE_END_EXCLUSIVE)
            .isEqualTo(Instant.parse("2100-01-01T00:00:00Z"));
    }

    @Test
    void 기간을_지정하면_한국_시간_하루_경계로_변환한다() {
        LocalDate day = LocalDate.parse("2026-11-02");
        given(aiCallMetricsPort.find(day, day, CallUsageUnit.DAY)).willReturn(new AiCallMetrics(List.of(),
            EMPTY_TOTALS));
        givenAbnormal(List.of());

        service.getMetrics(CallUsageUnit.DAY, day, day);

        ArgumentCaptor<Instant> fromCaptor = ArgumentCaptor.forClass(Instant.class);
        ArgumentCaptor<Instant> toCaptor = ArgumentCaptor.forClass(Instant.class);
        verify(callHistoryRepository).aggregateAbnormal(anyString(), anyString(), fromCaptor.capture(),
            toCaptor.capture(), anyList(), anyList());
        assertThat(fromCaptor.getValue()).isEqualTo(Instant.parse("2026-11-01T15:00:00Z"));
        assertThat(toCaptor.getValue()).isEqualTo(Instant.parse("2026-11-02T15:00:00Z"));
    }

    @Test
    void 합계_행은_AI_합계와_비정상_합을_담는다() {
        AiCallMetricsTotals totals = new AiCallMetricsTotals(128, 121, 2900, 790, 1910, new BigDecimal("5.37"));
        givenAi(CallUsageUnit.DAY, List.of(period("2026-11-02", 4, 810, 1740, "0.31")), totals);
        givenAbnormal(List.of(new TestAbnormalRow("2026-11-02", 1), new TestAbnormalRow("2026-11-05", 2)));

        AdminAiMetricsResponse response = service.getMetrics(CallUsageUnit.DAY, null, null);

        AdminAiMetricsRow total = response.total();
        assertThat(total.periodStart()).isNull();
        assertThat(total.callCount()).isEqualTo(128);
        assertThat(total.measuredCallCount()).isEqualTo(121);
        assertThat(total.turnCount()).isEqualTo(2900);
        assertThat(total.p50LatencyMillis()).isEqualTo(790);
        assertThat(total.p95LatencyMillis()).isEqualTo(1910);
        assertThat(total.estimatedCostUsd()).isEqualByComparingTo("5.37");
        assertThat(total.abnormalCallCount()).isEqualTo(3);
    }

    @Test
    void AI_서버가_불가하면_unavailable이고_예외를_올리지_않는다() {
        given(aiCallMetricsPort.find(null, null, CallUsageUnit.DAY))
            .willThrow(new CustomException(ErrorCode.AI_SERVER_UNAVAILABLE));

        AdminAiMetricsResponse response = service.getMetrics(CallUsageUnit.DAY, null, null);

        assertThat(response.unavailable()).isTrue();
        assertThat(response.rows()).isEmpty();
        assertThat(response.total().callCount()).isZero();
        assertThat(response.total().abnormalCallCount()).isZero();
        assertThat(response.total().estimatedCostUsd()).isEqualByComparingTo(BigDecimal.ZERO);
        verifyNoInteractions(callHistoryRepository);
    }

    @Test
    void AI_기간이_허용_범위를_벗어나면_unavailable로_취급한다() {
        givenAi(CallUsageUnit.DAY, List.of(period("0001-01-01", 1, 700, 900, "0.10"),
            period("2026-11-02", 4, 810, 1740, "0.31")), EMPTY_TOTALS);

        AdminAiMetricsResponse response = service.getMetrics(CallUsageUnit.DAY, null, null);

        assertThat(response.unavailable()).isTrue();
        assertThat(response.rows()).isEmpty();
        assertThat(response.total().callCount()).isZero();
        verifyNoInteractions(callHistoryRepository);
    }

    @Test
    void AI_기간이_2100년_이후면_unavailable로_취급한다() {
        givenAi(CallUsageUnit.DAY, List.of(period("2100-01-01", 1, 700, 900, "0.10")), EMPTY_TOTALS);

        assertThat(service.getMetrics(CallUsageUnit.DAY, null, null).unavailable()).isTrue();
    }

    @Test
    void AI_기간이_허용_범위의_경계_안이면_그대로_쓴다() {
        givenAi(CallUsageUnit.MONTH, List.of(period("2000-01-01", 1, 700, 900, "0.10"),
            period("2000-02-01", 1, 700, 900, "0.10")), EMPTY_TOTALS);
        givenAbnormal(List.of());

        AdminAiMetricsResponse response = service.getMetrics(CallUsageUnit.MONTH, null, null);

        assertThat(response.unavailable()).isFalse();
        assertThat(response.rows()).hasSize(2);
    }

    @Test
    void AI_서버의_다른_오류는_그대로_전파된다() {
        given(aiCallMetricsPort.find(null, null, CallUsageUnit.DAY))
            .willThrow(new CustomException(ErrorCode.INVALID_REQUEST));

        assertThatThrownBy(() -> service.getMetrics(CallUsageUnit.DAY, null, null))
            .isInstanceOf(CustomException.class)
            .extracting(exception -> ((CustomException) exception).getErrorCode())
            .isEqualTo(ErrorCode.INVALID_REQUEST);
    }

    @Test
    void 시작일이_종료일보다_늦으면_INVALID_REQUEST() {
        assertThatThrownBy(() -> service.getMetrics(CallUsageUnit.DAY, LocalDate.parse("2026-11-03"),
            LocalDate.parse("2026-11-02")))
            .isInstanceOf(CustomException.class)
            .extracting(exception -> ((CustomException) exception).getErrorCode())
            .isEqualTo(ErrorCode.INVALID_REQUEST);
        verifyNoInteractions(aiCallMetricsPort, callHistoryRepository);
    }

    @Test
    void 요약은_AI를_한_번만_호출하고_오늘_행을_고른다() {
        AiCallMetricsTotals totals = new AiCallMetricsTotals(128, 121, 2900, 790, 1910, new BigDecimal("5.37"));
        givenAi(CallUsageUnit.DAY, List.of(
            period("2026-11-09", 3, 700, 900, "0.10"),
            period("2026-11-10", 5, 820, 1740, "0.40")), totals);
        givenAbnormal(List.of(new TestAbnormalRow("2026-11-10", 2), new TestAbnormalRow("2026-11-01", 1)));

        AdminAiSummaryResponse summary = service.getSummary();

        verify(aiCallMetricsPort, times(1)).find(null, null, CallUsageUnit.DAY);
        assertThat(summary.unavailable()).isFalse();
        assertThat(summary.today().periodStart()).isEqualTo(LocalDate.parse("2026-11-10"));
        assertThat(summary.today().callCount()).isEqualTo(5);
        assertThat(summary.today().p95LatencyMillis()).isEqualTo(1740);
        assertThat(summary.today().abnormalCallCount()).isEqualTo(2);
        assertThat(summary.allTime().callCount()).isEqualTo(128);
        assertThat(summary.allTime().abnormalCallCount()).isEqualTo(3);
    }

    @Test
    void 요약의_오늘은_UTC가_아니라_한국_날짜다() {
        // UTC로는 2026-11-09 16:00이지만 KST로는 2026-11-10 01:00이다
        Clock earlyKoreanMorningClock = Clock.fixed(Instant.parse("2026-11-09T16:00:00Z"), ZoneOffset.UTC);
        AdminAiMetricsService earlyMorningService = new AdminAiMetricsService(aiCallMetricsPort,
            callHistoryRepository, earlyKoreanMorningClock, KOREA_ZONE_ID);
        givenAi(CallUsageUnit.DAY, List.of(
            period("2026-11-09", 3, 700, 900, "0.10"),
            period("2026-11-10", 5, 820, 1740, "0.40")), EMPTY_TOTALS);
        givenAbnormal(List.of());

        AdminAiSummaryResponse summary = earlyMorningService.getSummary();

        assertThat(summary.today().periodStart()).isEqualTo(LocalDate.parse("2026-11-10"));
        assertThat(summary.today().callCount()).isEqualTo(5);
    }

    @Test
    void 요약에서_오늘_행이_없으면_빈_행이다() {
        givenAi(CallUsageUnit.DAY, List.of(period("2026-11-09", 3, 700, 900, "0.10")), EMPTY_TOTALS);
        givenAbnormal(List.of());

        AdminAiSummaryResponse summary = service.getSummary();

        assertThat(summary.today().callCount()).isZero();
        assertThat(summary.today().p50LatencyMillis()).isNull();
        assertThat(summary.today().p95LatencyMillis()).isNull();
        assertThat(summary.today().estimatedCostUsd()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(summary.today().abnormalCallCount()).isZero();
    }

    @Test
    void 요약에서_AI_서버가_불가하면_unavailable이다() {
        given(aiCallMetricsPort.find(null, null, CallUsageUnit.DAY))
            .willThrow(new CustomException(ErrorCode.AI_SERVER_UNAVAILABLE));

        AdminAiSummaryResponse summary = service.getSummary();

        assertThat(summary.unavailable()).isTrue();
        assertThat(summary.today().callCount()).isZero();
        assertThat(summary.allTime().callCount()).isZero();
        verify(aiCallMetricsPort, times(1)).find(null, null, CallUsageUnit.DAY);
    }

    private void givenAi(CallUsageUnit unit, List<AiCallMetricsPeriod> periods, AiCallMetricsTotals totals) {
        given(aiCallMetricsPort.find(null, null, unit)).willReturn(new AiCallMetrics(periods, totals));
    }

    private void givenAbnormal(List<AbnormalCallRow> rows) {
        given(callHistoryRepository.aggregateAbnormal(anyString(), anyString(), any(), any(), anyList(), anyList()))
            .willReturn(rows);
    }

    private static AiCallMetricsPeriod period(String periodStart, long callCount, Integer p50, Integer p95,
        String cost) {
        return new AiCallMetricsPeriod(LocalDate.parse(periodStart), callCount, callCount, callCount * 24, p50, p95,
            new BigDecimal(cost));
    }

    private record TestAbnormalRow(String periodStart, long abnormalCount) implements AbnormalCallRow {

        @Override
        public String getPeriodStart() {
            return periodStart;
        }

        @Override
        public long getAbnormalCount() {
            return abnormalCount;
        }

    }

}
