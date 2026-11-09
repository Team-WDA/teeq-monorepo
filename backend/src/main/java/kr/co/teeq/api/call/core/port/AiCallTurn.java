package kr.co.teeq.api.call.core.port;

/**
 * AI 서버 통화 대화의 발화 한 건. 지연 시간은 측정되지 않았으면 null이다.
 */
public record AiCallTurn(
    int index,
    AiCallTurnRole role,
    String text,
    boolean interrupted,
    Integer endToEndLatencyMillis,
    Integer llmFirstTokenMillis
) {

}
