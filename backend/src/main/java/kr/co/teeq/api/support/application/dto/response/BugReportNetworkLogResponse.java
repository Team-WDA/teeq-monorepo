package kr.co.teeq.api.support.application.dto.response;

import java.time.Instant;
import java.util.Map;

/**
 * 저장된 네트워크 기록 JSON을 되읽은 한 건. 필드 이름은 저장할 때 직렬화한 요청 레코드와 같다.
 */
public record BugReportNetworkLogResponse(
    Instant startedAt,
    String method,
    String url,
    Map<String, String> requestHeaders,
    String requestBody,
    Boolean requestBodyTruncated,
    Integer statusCode,
    Map<String, String> responseHeaders,
    String responseBody,
    Boolean responseBodyTruncated,
    Integer durationMilliseconds,
    String errorDescription
) {

}
