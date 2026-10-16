package kr.teeq.api.call.core.port;

import java.util.UUID;

// AI 서버에 통화 세션 생성을 요청하는 port
public interface AiCallSessionPort {

    AiCallSession createSession(UUID memberId, long maxDurationSeconds);

}
