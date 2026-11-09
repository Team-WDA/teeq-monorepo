package kr.co.teeq.api.call.infrastructure.adapter;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import kr.co.teeq.api.call.core.port.AiCallDetail;
import kr.co.teeq.api.call.core.port.AiCallDetailPort;
import kr.co.teeq.api.call.core.port.AiCallTurn;
import kr.co.teeq.api.call.core.port.AiCallTurnRole;
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

    private final RestClient restClient;
    private final AiServerProperties properties;

    public AiServerCallDetailAdapter(
        @Qualifier("callRestClient") RestClient callRestClient,
        AiServerProperties properties
    ) {
        this.restClient = callRestClient;
        this.properties = properties;
    }

    // 재시도하지 않는다. 404는 세션 없음, 그 외 실패는 원인을 cause로만 남기고 화면에는 노출하지 않는다
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
            return Optional.empty();
        } catch (RestClientException exception) {
            throw new CustomException(ErrorCode.AI_SERVER_UNAVAILABLE, exception);
        }
        if (responseBody == null) {
            throw invalidResponse("응답 본문이 비어 있습니다");
        }
        if (!(responseBody.get(SESSION_ID_FIELD) instanceof String responseSessionId)
            || !responseSessionId.equals(callSessionId)) {
            log.warn("AI 서버 통화 상세 응답의 {}가 없거나 요청과 다릅니다", SESSION_ID_FIELD);
        }
        return Optional.of(new AiCallDetail(callSessionId,
            readText(responseBody.get(SUMMARY_FIELD)),
            readText(responseBody.get(LLM_MODEL_FIELD)),
            readCost(responseBody.get(ESTIMATED_COST_FIELD)),
            responseBody.get(MEMORY_INJECTED_FIELD) instanceof Boolean memoryInjected ? memoryInjected : null,
            readTurns(responseBody.get(TURNS_FIELD))));
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
            readMillis(turn.get(END_TO_END_LATENCY_FIELD)), readMillis(turn.get(LLM_FIRST_TOKEN_FIELD)));
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

    private Integer readMillis(Object rawMillis) {
        return rawMillis instanceof Number number ? number.intValue() : null;
    }

    private CustomException invalidResponse(String reason) {
        log.error("AI 서버 통화 상세 응답이 계약에 맞지 않습니다: {}", reason);
        return new CustomException(ErrorCode.AI_SERVER_UNAVAILABLE);
    }

}
