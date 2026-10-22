package kr.co.teeq.api.support.application.dto.response;

import java.time.Instant;

/**
 * 저장된 에러 로그 JSON을 되읽은 한 건. 필드 이름은 저장할 때 직렬화한 요청 레코드와 같다.
 */
public record BugReportErrorLogResponse(
    Instant timestamp,
    String level,
    String name,
    String message,
    String errorDescription,
    String stackTraceText
) {

}
