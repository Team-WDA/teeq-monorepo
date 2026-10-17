package kr.teeq.api.call.core.constant;

import java.time.LocalDate;

/**
 * 사용량 집계 단위. 집계 쿼리의 date_trunc 단위와 기간 이동 규칙을 함께 가진다.
 */
public enum CallUsageUnit {
    DAY("day"),
    MONTH("month");

    private final String truncateField;

    CallUsageUnit(String truncateField) {
        this.truncateField = truncateField;
    }

    // PostgreSQL date_trunc에 넘기는 단위 이름
    public String truncateField() {
        return truncateField;
    }

    // 기간 시작 날짜를 해당 단위의 시작 날짜로 맞춘다(MONTH는 그 달 1일)
    public LocalDate alignToPeriodStart(LocalDate date) {
        return this == MONTH ? date.withDayOfMonth(1) : date;
    }

    public LocalDate nextPeriodStart(LocalDate periodStart) {
        return this == MONTH ? periodStart.plusMonths(1) : periodStart.plusDays(1);
    }
}
