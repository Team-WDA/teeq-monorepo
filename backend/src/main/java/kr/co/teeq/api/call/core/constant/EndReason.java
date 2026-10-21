package kr.co.teeq.api.call.core.constant;

/**
 * 통화가 끝난 이유. AI 서버가 사용량 보고에 실어 보낸다.
 */
public enum EndReason {
    USER_HANGUP,
    USER_DISCONNECTED,
    LIMIT_REACHED,
    AGENT_ERROR,
    // AI 서버가 에이전트 배정에 실패한 경우. AI 서버는 이 값으로 보고하지 않는다
    DISPATCH_FAILED
}
