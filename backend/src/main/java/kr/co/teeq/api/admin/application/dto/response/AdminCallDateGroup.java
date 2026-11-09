package kr.co.teeq.api.admin.application.dto.response;

import java.time.LocalDate;
import java.util.List;

/**
 * 한국 시간 기준 같은 날짜에 시작한 통화 행 묶음.
 */
public record AdminCallDateGroup(
    LocalDate date,
    List<AdminCallRowView> rows
) {

}
