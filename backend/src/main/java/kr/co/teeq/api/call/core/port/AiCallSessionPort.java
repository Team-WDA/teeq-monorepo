package kr.co.teeq.api.call.core.port;

// AI 서버에 통화 세션 생성을 요청하는 port
public interface AiCallSessionPort {

    AiCallSession createSession(AiCallSessionRequest request);

}
