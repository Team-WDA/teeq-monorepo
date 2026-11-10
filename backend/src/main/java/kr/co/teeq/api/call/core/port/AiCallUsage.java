package kr.co.teeq.api.call.core.port;

import java.math.BigDecimal;

/**
 * AI 서버가 기록한 통화 한 건의 모델별 사용량. kind는 소문자(stt/llm/tts)로 오며 나머지는 null일 수 있다.
 */
public record AiCallUsage(
    String kind,
    String provider,
    String model,
    BigDecimal audioSeconds,
    Long inputTokens,
    Long cachedInputTokens,
    Long outputTokens,
    Long chars
) {

}
