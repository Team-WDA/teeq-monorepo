package kr.co.teeq.api.call.core.port;

import java.math.BigDecimal;
import java.util.List;

/**
 * AI 서버가 가진 통화 한 건의 상세. resultStatus, summary, llmModel, estimatedCostUsd, memoryInjected는 null일 수 있고
 * turns, usages가 null이면 빈 목록으로 둔다.
 * quality, firstAiAudioMillis, promptVersion, callIndex도 AI 서버가 보내지 않으면 null이다.
 */
public record AiCallDetail(
    String sessionId,
    AiCallResultStatus resultStatus,
    String summary,
    String llmModel,
    BigDecimal estimatedCostUsd,
    Boolean memoryInjected,
    List<AiCallTurn> turns,
    AiCallQuality quality,
    Integer firstAiAudioMillis,
    String promptVersion,
    Integer callIndex,
    List<AiCallUsage> usages
) {

    public AiCallDetail {
        turns = turns == null ? List.of() : List.copyOf(turns);
        usages = usages == null ? List.of() : List.copyOf(usages);
    }

}
