package kr.co.teeq.api.admin.application.service;

import java.util.Optional;
import kr.co.teeq.api.admin.application.dto.response.AdminCallDetailResponse;
import kr.co.teeq.api.admin.application.dto.response.AdminCallDetailResponse.ConversationState;
import kr.co.teeq.api.call.application.dto.response.CallHistoryItemResponse;
import kr.co.teeq.api.call.application.service.CallHistoryQueryService;
import kr.co.teeq.api.call.core.port.AiCallDetail;
import kr.co.teeq.api.call.core.port.AiCallDetailPort;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * 관리자 통화 상세. BE 통화 기록과 AI 서버의 대화를 합치고, AI 서버 실패는 대화 영역에만 국한한다.
 * AI 서버 호출 중에는 DB 트랜잭션을 열어 두지 않으므로 @Transactional을 붙이지 않는다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AdminCallDetailService {

    private final CallHistoryQueryService callHistoryQueryService;
    private final AiCallDetailPort aiCallDetailPort;

    public AdminCallDetailResponse getDetail(String callSessionId) {
        CallHistoryItemResponse call = callHistoryQueryService.getBySessionId(callSessionId);
        Optional<AiCallDetail> aiDetail;
        try {
            aiDetail = aiCallDetailPort.find(callSessionId);
        } catch (CustomException exception) {
            if (exception.getErrorCode() != ErrorCode.AI_SERVER_UNAVAILABLE) {
                throw exception;
            }
            log.warn("AI 서버 통화 상세 조회 실패로 대화 없이 표시합니다", exception);
            return new AdminCallDetailResponse(call, ConversationState.UNAVAILABLE, null);
        }
        if (aiDetail.isEmpty()) {
            return new AdminCallDetailResponse(call, ConversationState.NOT_RECORDED, null);
        }
        ConversationState state = aiDetail.get().turns().isEmpty()
            ? ConversationState.EXPIRED : ConversationState.LOADED;
        return new AdminCallDetailResponse(call, state, aiDetail.get());
    }

}
