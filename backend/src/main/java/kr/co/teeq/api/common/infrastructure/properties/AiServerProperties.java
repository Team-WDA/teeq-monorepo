package kr.co.teeq.api.common.infrastructure.properties;

import org.springframework.boot.context.properties.ConfigurationProperties;

// AI 서버 호출 설정. 값은 시크릿이므로 예외 메시지에 넣지 않는다
@ConfigurationProperties(prefix = "ai-server")
public record AiServerProperties(String baseUrl, String authHeaderName, String authHeaderValue) {

    // AI 서버 API 공통 경로 접두사
    public static final String API_PATH_PREFIX = "/internal/v1";

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
    }

    // baseUrl 끝의 슬래시를 제거한 뒤 API 경로 접두사를 붙인 RestClient 기준 주소
    public String apiBaseUrl() {
        String trimmedBaseUrl = baseUrl.endsWith("/") ? baseUrl.substring(0, baseUrl.length() - 1) : baseUrl;
        return trimmedBaseUrl + API_PATH_PREFIX;
    }

}
