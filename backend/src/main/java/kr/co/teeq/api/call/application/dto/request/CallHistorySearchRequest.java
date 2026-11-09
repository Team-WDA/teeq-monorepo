package kr.co.teeq.api.call.application.dto.request;

import java.time.LocalDate;
import java.util.UUID;
import kr.co.teeq.api.call.core.constant.CallStatus;

/**
 * 관리자 통화 목록 검색 조건. 모든 필터는 선택이며 from, to는 한국 시간 기준 날짜(양 끝 포함)다.
 */
public record CallHistorySearchRequest(
    UUID memberId,
    String keyword,
    LocalDate from,
    LocalDate to,
    CallStatus status,
    boolean abnormalOnly
) {

}
