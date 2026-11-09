package kr.co.teeq.api.admin.application.dto.response;

/**
 * 통화 상태 필터 선택지. name은 쿼리 값(CallStatus 이름), label은 한국어 표시 문구다.
 */
public record AdminCallStatusOption(
    String name,
    String label
) {

}
