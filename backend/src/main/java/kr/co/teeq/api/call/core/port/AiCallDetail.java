package kr.co.teeq.api.call.core.port;

import java.math.BigDecimal;
import java.util.List;

/**
 * AI 서버가 가진 통화 한 건의 상세. summary, llmModel, estimatedCostUsd, memoryInjected는 null일 수 있고
 * turns가 null이면 빈 목록으로 둔다.
 */
public record AiCallDetail(
    String sessionId,
    String summary,
    String llmModel,
    BigDecimal estimatedCostUsd,
    Boolean memoryInjected,
    List<AiCallTurn> turns
) {

    public AiCallDetail {
        turns = turns == null ? List.of() : List.copyOf(turns);
    }

}
