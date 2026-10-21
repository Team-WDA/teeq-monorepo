package kr.co.teeq.api.call.core.port;

import java.util.Map;

// callSessionId는 AI 서버가 발급한 세션 식별자, promptVersion·llmModel은 통화 기록에만 쓰며 없으면 null,
// connection은 앱이 접속에 쓰는 나머지 필드
public record AiCallSession(String callSessionId, String promptVersion, String llmModel,
                            Map<String, Object> connection) {

}
