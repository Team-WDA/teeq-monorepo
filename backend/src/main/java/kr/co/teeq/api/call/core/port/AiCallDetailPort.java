package kr.co.teeq.api.call.core.port;

import java.util.Optional;

public interface AiCallDetailPort {

    /**
     * 통화 세션의 상세를 AI 서버에서 조회한다. AI 서버에 세션이 없으면 빈 값이고,
     * 그 외 실패는 AI_SERVER_UNAVAILABLE CustomException이다.
     */
    Optional<AiCallDetail> find(String callSessionId);

}
