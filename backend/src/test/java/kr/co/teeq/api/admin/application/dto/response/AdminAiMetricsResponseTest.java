package kr.co.teeq.api.admin.application.dto.response;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import kr.co.teeq.api.call.core.constant.CallUsageUnit;
import org.junit.jupiter.api.Test;

class AdminAiMetricsResponseTest {

    @Test
    void 최대_p95가_0이면_막대_높이는_0이다() {
        AdminAiMetricsRow zeroRow = row(LocalDate.parse("2026-11-01"), 0);
        AdminAiMetricsResponse response = response(List.of(zeroRow, row(LocalDate.parse("2026-11-02"), null)));

        assertThat(response.barHeightPercent(zeroRow)).isZero();
    }

    @Test
    void p95가_null이면_막대_높이는_0이다() {
        AdminAiMetricsRow nullRow = row(LocalDate.parse("2026-11-02"), null);
        AdminAiMetricsResponse response = response(List.of(row(LocalDate.parse("2026-11-01"), 1000), nullRow));

        assertThat(response.barHeightPercent(nullRow)).isZero();
    }

    @Test
    void 모든_p95가_null이어도_나누기_오류_없이_0이다() {
        AdminAiMetricsRow nullRow = row(LocalDate.parse("2026-11-01"), null);
        AdminAiMetricsResponse response = response(List.of(nullRow));

        assertThat(response.barHeightPercent(nullRow)).isZero();
    }

    @Test
    void 최대_p95를_100으로_둔_비율이다() {
        AdminAiMetricsRow maxRow = row(LocalDate.parse("2026-11-01"), 2000);
        AdminAiMetricsRow halfRow = row(LocalDate.parse("2026-11-02"), 1000);
        AdminAiMetricsRow thirdRow = row(LocalDate.parse("2026-11-03"), 667);
        AdminAiMetricsResponse response = response(List.of(maxRow, halfRow, thirdRow));

        assertThat(response.barHeightPercent(maxRow)).isEqualTo(100);
        assertThat(response.barHeightPercent(halfRow)).isEqualTo(50);
        assertThat(response.barHeightPercent(thirdRow)).isEqualTo(33);
    }

    @Test
    void 최대_p95는_생성할_때_한_번_계산해_보관한다() {
        AdminAiMetricsResponse response = response(List.of(row(LocalDate.parse("2026-11-01"), 2000),
            row(LocalDate.parse("2026-11-02"), null), row(LocalDate.parse("2026-11-03"), 1000)));

        assertThat(response.maxP95LatencyMillis()).isEqualTo(2000);
        assertThat(response(List.of()).maxP95LatencyMillis()).isZero();
    }

    private static AdminAiMetricsResponse response(List<AdminAiMetricsRow> rows) {
        return new AdminAiMetricsResponse(CallUsageUnit.DAY, null, null, false, rows,
            AdminAiMetricsRow.empty(null));
    }

    private static AdminAiMetricsRow row(LocalDate periodStart, Integer p95LatencyMillis) {
        return new AdminAiMetricsRow(periodStart, 1, 1, 10, null, p95LatencyMillis, BigDecimal.ZERO, 0);
    }

}
