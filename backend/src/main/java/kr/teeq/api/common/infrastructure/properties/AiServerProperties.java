package kr.teeq.api.common.infrastructure.properties;

import org.springframework.boot.context.properties.ConfigurationProperties;

// AI 서버 호출 설정. 값은 시크릿이므로 예외 메시지에 넣지 않는다
@ConfigurationProperties(prefix = "ai-server")
public record AiServerProperties(String baseUrl, String authHeaderName, String authHeaderValue, long timeoutMillis) {

    public AiServerProperties {
        if (baseUrl == null || baseUrl.isBlank()) {
            throw new IllegalStateException("ai-server.base-url이 비어 있습니다");
        }
        if (authHeaderName == null || authHeaderName.isBlank()) {
            throw new IllegalStateException("ai-server.auth-header-name이 비어 있습니다");
        }
        if (authHeaderValue == null || authHeaderValue.isBlank()) {
            throw new IllegalStateException("ai-server.auth-header-value가 비어 있습니다");
        }
        if (timeoutMillis <= 0) {
            throw new IllegalStateException("ai-server.timeout-millis는 0보다 커야 합니다");
        }
    }

}
