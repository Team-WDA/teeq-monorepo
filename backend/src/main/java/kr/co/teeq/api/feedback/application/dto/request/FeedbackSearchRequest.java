package kr.co.teeq.api.feedback.application.dto.request;

import java.time.LocalDate;
import java.util.UUID;

/**
 * 관리자 피드백 목록 검색 조건. null인 조건은 걸지 않는다. 기간은 필수 피드백 제출 시각(KST 날짜, 양끝 포함) 기준이다.
 */
public record FeedbackSearchRequest(
    UUID memberId,
    LocalDate from,
    LocalDate to,
    Integer rating,
    boolean detailedOnly
) {

}
