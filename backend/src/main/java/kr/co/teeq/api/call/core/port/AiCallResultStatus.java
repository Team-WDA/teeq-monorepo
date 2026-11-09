package kr.co.teeq.api.call.core.port;

/**
 * AI 서버가 통화 결과를 받은 상태. PENDING 아직 받지 못함, RECEIVED 수신함, MISSING 끝내 수신되지 않음.
 */
public enum AiCallResultStatus {
    PENDING,
    RECEIVED,
    MISSING
}
