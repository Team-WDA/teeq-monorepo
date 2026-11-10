package kr.co.teeq.api.call.infrastructure.adapter;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import kr.co.teeq.api.call.core.port.AiCallDetail;
import kr.co.teeq.api.call.core.port.AiCallDetailPort;
import kr.co.teeq.api.call.core.port.AiCallQuality;
import kr.co.teeq.api.call.core.port.AiCallResultStatus;
import kr.co.teeq.api.call.core.port.AiCallTurn;
import kr.co.teeq.api.call.core.port.AiCallTurnRole;
import kr.co.teeq.api.call.core.port.AiCallUsage;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.common.infrastructure.properties.AiServerProperties;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Slf4j
@Component
public class AiServerCallDetailAdapter implements AiCallDetailPort {

    private static final String SESSION_ID_FIELD = "sessionId";
    private static final String RESULT_STATUS_FIELD = "resultStatus";
    private static final String SUMMARY_FIELD = "summary";
    private static final String LLM_MODEL_FIELD = "llmModel";
    private static final String ESTIMATED_COST_FIELD = "estimatedCostUsd";
    private static final String MEMORY_INJECTED_FIELD = "memoryInjected";
    private static final String TURNS_FIELD = "turns";
    private static final String INDEX_FIELD = "index";
    private static final String ROLE_FIELD = "role";
    private static final String TEXT_FIELD = "text";
    private static final String INTERRUPTED_FIELD = "interrupted";
    private static final String END_TO_END_LATENCY_FIELD = "endToEndLatencyMillis";
    private static final String LLM_FIRST_TOKEN_FIELD = "llmFirstTokenMillis";
    private static final String TTS_FIRST_BYTE_FIELD = "ttsFirstByteMillis";
    private static final String TRANSCRIPTION_DELAY_FIELD = "transcriptionDelayMillis";
    private static final String END_OF_TURN_DELAY_FIELD = "endOfTurnDelayMillis";
    private static final String QUALITY_FIELD = "quality";
    private static final String P50_LATENCY_FIELD = "p50LatencyMillis";
    private static final String P95_LATENCY_FIELD = "p95LatencyMillis";
    private static final String USER_INTERRUPTIONS_FIELD = "userInterruptions";
    private static final String EARLY_HANGUP_FIELD = "earlyHangup";
    private static final String FIRST_AI_AUDIO_FIELD = "firstAiAudioMillis";
    private static final String PROMPT_VERSION_FIELD = "promptVersion";
    private static final String CALL_INDEX_FIELD = "callIndex";
    private static final String USAGE_FIELD = "usage";
    private static final String KIND_FIELD = "kind";
    private static final String PROVIDER_FIELD = "provider";
    private static final String MODEL_FIELD = "model";
    private static final String AUDIO_SECONDS_FIELD = "audioSeconds";
    private static final String INPUT_TOKENS_FIELD = "inputTokens";
    private static final String CACHED_INPUT_TOKENS_FIELD = "cachedInputTokens";
    private static final String OUTPUT_TOKENS_FIELD = "outputTokens";
    private static final String CHARS_FIELD = "chars";
    private static final String DETAIL_FIELD = "detail";
    private static final String CODE_FIELD = "code";
    private static final String SESSION_NOT_FOUND_CODE = "SESSION_NOT_FOUND";

    private final RestClient restClient;
    private final AiServerProperties properties;

    public AiServerCallDetailAdapter(
        @Qualifier("callRestClient") RestClient callRestClient,
        AiServerProperties properties
    ) {
        this.restClient = callRestClient;
        this.properties = properties;
    }

    // 재시도하지 않는다. SESSION_NOT_FOUND 404만 세션 없음이고,
    // 그 외 404를 포함한 실패는 원인을 cause로만 남기고 화면에는 노출하지 않는다
    @Override
    public Optional<AiCallDetail> find(String callSessionId) {
        Map<String, Object> responseBody;
        try {
            responseBody = restClient.get()
                .uri("/calls/{sessionId}", callSessionId)
                .header(properties.authHeaderName(), properties.authHeaderValue())
                .retrieve()
                .body(new ParameterizedTypeReference<Map<String, Object>>() {
                });
        } catch (HttpClientErrorException.NotFound exception) {
            if (isSessionNotFound(exception)) {
                return Optional.empty();
            }
            log.warn("AI 서버 통화 상세 404 응답이 세션 없음이 아닙니다(경로 오류 등)");
            throw new CustomException(ErrorCode.AI_SERVER_UNAVAILABLE, exception);
        } catch (RestClientException exception) {
            throw new CustomException(ErrorCode.AI_SERVER_UNAVAILABLE, exception);
        }
        if (responseBody == null) {
            throw invalidResponse("응답 본문이 비어 있습니다");
        }
        if (responseBody.get(SESSION_ID_FIELD) instanceof String responseSessionId) {
            if (!responseSessionId.equals(callSessionId)) {
                throw invalidResponse(SESSION_ID_FIELD + "가 요청과 다릅니다");
            }
        } else {
            log.warn("AI 서버 통화 상세 응답에 {}가 없거나 문자열이 아닙니다", SESSION_ID_FIELD);
        }
        return Optional.of(new AiCallDetail(callSessionId,
            readResultStatus(responseBody.get(RESULT_STATUS_FIELD)),
            readText(responseBody.get(SUMMARY_FIELD)),
            readText(responseBody.get(LLM_MODEL_FIELD)),
            readCost(responseBody.get(ESTIMATED_COST_FIELD)),
            responseBody.get(MEMORY_INJECTED_FIELD) instanceof Boolean memoryInjected ? memoryInjected : null,
            readTurns(responseBody.get(TURNS_FIELD)),
            readQuality(responseBody.get(QUALITY_FIELD)),
            readMillis(responseBody.get(FIRST_AI_AUDIO_FIELD)),
            readText(responseBody.get(PROMPT_VERSION_FIELD)),
            readMillis(responseBody.get(CALL_INDEX_FIELD)),
            readUsages(responseBody.get(USAGE_FIELD))));
    }

    // FastAPI는 detail 아래에 code를 감싸 내리고 문서에는 평평한 형태라 둘 다 받는다.
    // 읽지 못하면 일치하지 않는 것으로 본다
    private boolean isSessionNotFound(HttpClientErrorException.NotFound exception) {
        try {
            Map<String, Object> errorBody = exception.getResponseBodyAs(new ParameterizedTypeReference<>() {
            });
            if (errorBody == null) {
                return false;
            }
            Object code = errorBody.get(DETAIL_FIELD) instanceof Map<?, ?> detail
                ? detail.get(CODE_FIELD) : errorBody.get(CODE_FIELD);
            return SESSION_NOT_FOUND_CODE.equals(code);
        } catch (RuntimeException parseFailure) {
            return false;
        }
    }

    // 없거나 계약 밖의 값이면 오류 없이 null로 둔다
    private AiCallResultStatus readResultStatus(Object rawStatus) {
        if (!(rawStatus instanceof String statusName)) {
            return null;
        }
        try {
            return AiCallResultStatus.valueOf(statusName);
        } catch (IllegalArgumentException exception) {
            return null;
        }
    }

    private List<AiCallTurn> readTurns(Object rawTurns) {
        if (rawTurns == null) {
            return List.of();
        }
        if (!(rawTurns instanceof List<?> rawTurnList)) {
            throw invalidResponse(TURNS_FIELD + "가 배열이 아닙니다");
        }
        List<AiCallTurn> turns = new ArrayList<>();
        for (int position = 0; position < rawTurnList.size(); position++) {
            turns.add(readTurn(rawTurnList.get(position), position));
        }
        return turns;
    }

    private AiCallTurn readTurn(Object rawTurn, int position) {
        if (!(rawTurn instanceof Map<?, ?> turn)) {
            throw invalidResponse(TURNS_FIELD + "의 항목이 객체가 아닙니다");
        }
        int index = turn.get(INDEX_FIELD) instanceof Number number ? number.intValue() : position;
        String text = turn.get(TEXT_FIELD) instanceof String value ? value : "";
        boolean interrupted = turn.get(INTERRUPTED_FIELD) instanceof Boolean value && value;
        return new AiCallTurn(index, readRole(turn.get(ROLE_FIELD)), text, interrupted,
            readMillis(turn.get(END_TO_END_LATENCY_FIELD)), readMillis(turn.get(LLM_FIRST_TOKEN_FIELD)),
            readMillis(turn.get(TTS_FIRST_BYTE_FIELD)), readMillis(turn.get(TRANSCRIPTION_DELAY_FIELD)),
            readMillis(turn.get(END_OF_TURN_DELAY_FIELD)));
    }

    // 품질 지표는 선택 값이라 객체가 아니면 null이다
    private AiCallQuality readQuality(Object rawQuality) {
        if (!(rawQuality instanceof Map<?, ?> quality)) {
            return null;
        }
        return new AiCallQuality(readMillis(quality.get(P50_LATENCY_FIELD)), readMillis(quality.get(P95_LATENCY_FIELD)),
            readMillis(quality.get(USER_INTERRUPTIONS_FIELD)),
            quality.get(EARLY_HANGUP_FIELD) instanceof Boolean earlyHangup ? earlyHangup : null);
    }

    // 사용량은 선택 값이라 배열이 아니면 빈 목록이고 객체가 아닌 항목은 건너뛴다
    private List<AiCallUsage> readUsages(Object rawUsages) {
        if (!(rawUsages instanceof List<?> rawUsageList)) {
            return List.of();
        }
        List<AiCallUsage> usages = new ArrayList<>();
        for (Object rawUsage : rawUsageList) {
            if (rawUsage instanceof Map<?, ?> usage) {
                usages.add(new AiCallUsage(readText(usage.get(KIND_FIELD)), readText(usage.get(PROVIDER_FIELD)),
                    readText(usage.get(MODEL_FIELD)), readCost(usage.get(AUDIO_SECONDS_FIELD)),
                    readLong(usage.get(INPUT_TOKENS_FIELD)), readLong(usage.get(CACHED_INPUT_TOKENS_FIELD)),
                    readLong(usage.get(OUTPUT_TOKENS_FIELD)), readLong(usage.get(CHARS_FIELD))));
            }
        }
        return usages;
    }

    private AiCallTurnRole readRole(Object rawRole) {
        if (!(rawRole instanceof String roleName)) {
            throw invalidResponse(ROLE_FIELD + "가 없거나 문자열이 아닙니다");
        }
        try {
            return AiCallTurnRole.valueOf(roleName);
        } catch (IllegalArgumentException exception) {
            throw invalidResponse(ROLE_FIELD + "가 계약 밖의 값입니다");
        }
    }

    // 요약·모델명은 화면 부가 정보라 없거나 비어 있으면 null로 둔다
    private String readText(Object rawText) {
        return rawText instanceof String text && !text.isBlank() ? text : null;
    }

    // 부동소수점 오차를 피하려고 숫자의 문자열 표현으로 BigDecimal을 만든다
    private BigDecimal readCost(Object rawCost) {
        return rawCost instanceof Number number ? new BigDecimal(number.toString()) : null;
    }

    // 밀리초 외에 정수 값(통화 횟수, 끼어들기 횟수)도 같은 규칙(숫자만 Integer, 아니면 null)으로 읽는다
    private Integer readMillis(Object rawMillis) {
        return rawMillis instanceof Number number ? number.intValue() : null;
    }

    private Long readLong(Object rawNumber) {
        return rawNumber instanceof Number number ? number.longValue() : null;
    }

    private CustomException invalidResponse(String reason) {
        log.error("AI 서버 통화 상세 응답이 계약에 맞지 않습니다: {}", reason);
        return new CustomException(ErrorCode.AI_SERVER_UNAVAILABLE);
    }

}
