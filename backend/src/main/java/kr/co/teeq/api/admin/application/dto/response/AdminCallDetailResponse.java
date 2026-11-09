package kr.co.teeq.api.admin.application.dto.response;

import kr.co.teeq.api.call.application.dto.response.CallHistoryItemResponse;
import kr.co.teeq.api.call.core.port.AiCallDetail;

/**
 * 관리자 통화 상세. BE 통화 기록은 항상 있고, aiDetail은 conversationState가 LOADED, EXPIRED일 때만 있다.
 */
public record AdminCallDetailResponse(
    CallHistoryItemResponse call,
    ConversationState conversationState,
    AiCallDetail aiDetail
) {

    /**
     * 대화 영역의 상태. LOADED 대화 조회됨, EXPIRED AI 서버 보관 기간이 지나 대화 없음,
     * NOT_RECORDED AI 서버에 기록 없음, UNAVAILABLE AI 서버 호출 실패.
     */
    public enum ConversationState {
        LOADED,
        EXPIRED,
        NOT_RECORDED,
        UNAVAILABLE
    }

}
