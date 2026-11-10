package kr.co.teeq.api.call.core.port;

/**
 * AI 서버가 계산한 통화 한 건의 품질 지표. 측정되지 않은 값은 null이다.
 */
public record AiCallQuality(
    Integer p50LatencyMillis,
    Integer p95LatencyMillis,
    Integer userInterruptions,
    Boolean earlyHangup
) {

}
