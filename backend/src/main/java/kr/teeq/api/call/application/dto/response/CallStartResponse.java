package kr.teeq.api.call.application.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.Map;

public record CallStartResponse(
    @Schema(description = "AI 서버가 발급한 통화 세션 ID", example = "call-session-1234")
    String callSessionId,

    @Schema(description = "이번 통화의 허용 시간(초)", example = "1200")
    long maxDurationSeconds,

    @Schema(description = "앱이 통화 접속에 쓰는 AI 서버 응답의 나머지 필드")
    Map<String, Object> connection
) {

}
