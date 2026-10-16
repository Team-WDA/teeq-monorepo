package kr.teeq.api.call.core.port;

import java.util.Map;

// callSessionId는 AI 서버가 발급한 세션 식별자, connection은 앱이 접속에 쓰는 나머지 필드
public record AiCallSession(String callSessionId, Map<String, Object> connection) {

}
