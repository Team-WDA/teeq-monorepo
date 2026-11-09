package kr.co.teeq.api.admin.application.dto.response;

import kr.co.teeq.api.call.application.dto.response.CallHistoryItemResponse;
import kr.co.teeq.api.call.core.port.AiCallDetail;

/**
 * 관리자 통화 상세. BE 통화 기록은 항상 있고, aiDetail은 conversationState가 LOADED, RESULT_PENDING,
 * RESULT_MISSING, EMPTY일 때만 있다.
 */
public record AdminCallDetailResponse(
    CallHistoryItemResponse call,
    ConversationState conversationState,
    AiCallDetail aiDetail
) {

    /**
     * 대화 영역의 상태. LOADED 대화 조회됨, RESULT_PENDING 통화 결과를 아직 받지 못해 대화 없음,
     * RESULT_MISSING 통화 결과가 수신되지 않아 대화 없음, EMPTY 결과는 있으나 대화 없음,
     * NOT_RECORDED AI 서버에 기록 없음, UNAVAILABLE AI 서버 호출 실패.
     */
    public enum ConversationState {
        LOADED,
        RESULT_PENDING,
        RESULT_MISSING,
        EMPTY,
        NOT_RECORDED,
        UNAVAILABLE
    }

}
