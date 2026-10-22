package kr.co.teeq.api.support.infrastructure.properties;

import org.springframework.boot.context.properties.ConfigurationProperties;

// 버그 제보 알림 설정. 웹훅 URL은 시크릿이므로 예외 메시지에 값을 넣지 않는다
@ConfigurationProperties(prefix = "bug-report")
public record BugReportProperties(Discord discord, String adminBaseUrl) {

    public BugReportProperties {
        // discord 블록이 통째로 없으면 null로 바인딩된다
        if (discord == null) {
            throw new IllegalStateException("bug-report.discord가 비어 있습니다");
        }
        if (discord.webhookUrl() == null || discord.webhookUrl().isBlank()) {
            throw new IllegalStateException("bug-report.discord.webhook-url이 비어 있습니다");
        }
        if (adminBaseUrl == null || adminBaseUrl.isBlank()) {
            throw new IllegalStateException("bug-report.admin-base-url이 비어 있습니다");
        }
    }

    public record Discord(String webhookUrl) {

    }

}
