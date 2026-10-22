package kr.co.teeq.api.support.infrastructure.adapter;

import java.net.URI;
import java.util.List;
import java.util.Map;
import kr.co.teeq.api.support.core.port.BugReportNotification;
import kr.co.teeq.api.support.core.port.BugReportNotificationPort;
import kr.co.teeq.api.support.infrastructure.properties.BugReportProperties;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

@Slf4j
@Component
public class DiscordBugReportNotificationAdapter implements BugReportNotificationPort {

    // 링크 미리보기(embed)를 끈다
    private static final int SUPPRESS_EMBEDS_FLAG = 4;

    private final RestClient restClient;
    private final BugReportProperties properties;
    private final DiscordMessageFormatter messageFormatter;

    public DiscordBugReportNotificationAdapter(
        @Qualifier("bugReportRestClient") RestClient bugReportRestClient,
        BugReportProperties properties,
        DiscordMessageFormatter messageFormatter
    ) {
        this.restClient = bugReportRestClient;
        this.properties = properties;
        this.messageFormatter = messageFormatter;
    }

    // 알림은 부가 기능이라 실패해도 삼킨다. 예외 메시지(RestClientException, URI 파싱 오류)에 웹훅 URL이 들어 있으므로 클래스명만 남긴다
    @Override
    public void notify(BugReportNotification notification) {
        try {
            restClient.post()
                    .uri(URI.create(properties.discord().webhookUrl()))
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(toRequestBody(notification))
                    .retrieve()
                    .toBodilessEntity();
        } catch (RuntimeException exception) {
            log.warn("버그 제보 Discord 알림 전송 실패: bugReportId={}, 원인={}", notification.bugReportId(),
                    exception.getClass().getSimpleName());
        }
    }

    // allowed_mentions.parse를 비워 본문에 @everyone 등이 있어도 멘션이 나가지 않게 한다
    private Map<String, Object> toRequestBody(BugReportNotification notification) {
        return Map.of(
                "content", messageFormatter.format(notification, properties.adminBaseUrl()),
                "allowed_mentions", Map.of("parse", List.of()),
                "flags", SUPPRESS_EMBEDS_FLAG);
    }

}
