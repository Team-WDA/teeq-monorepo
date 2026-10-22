package kr.co.teeq.api.support.infrastructure.adapter;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicReference;
import kr.co.teeq.api.support.core.constant.BugReportPlatform;
import kr.co.teeq.api.support.core.constant.BugReportSource;
import kr.co.teeq.api.support.core.port.BugReportNotification;
import kr.co.teeq.api.support.infrastructure.properties.BugReportProperties;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.web.client.RestClient;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

class DiscordBugReportNotificationAdapterTest {

    private static final String ADMIN_BASE_URL = "https://admin.example.invalid";

    private HttpServer server;
    private int responseStatus;
    private final AtomicReference<String> requestBody = new AtomicReference<>();
    private ListAppender<ILoggingEvent> logAppender;
    private Logger adapterLogger;

    @BeforeEach
    void setUp() throws IOException {
        responseStatus = 204;
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/example.invalid/webhook/token", exchange -> {
            requestBody.set(new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8));
            exchange.sendResponseHeaders(responseStatus, -1);
            exchange.close();
        });
        server.start();

        adapterLogger = (Logger) LoggerFactory.getLogger(DiscordBugReportNotificationAdapter.class);
        logAppender = new ListAppender<>();
        logAppender.start();
        adapterLogger.addAppender(logAppender);
    }

    @AfterEach
    void tearDown() {
        server.stop(0);
        adapterLogger.detachAppender(logAppender);
    }

    private DiscordBugReportNotificationAdapter adapterFor(String webhookUrl) {
        return new DiscordBugReportNotificationAdapter(RestClient.builder().build(),
            new BugReportProperties(new BugReportProperties.Discord(webhookUrl), ADMIN_BASE_URL),
            new DiscordMessageFormatter());
    }

    private String liveWebhookUrl() {
        return "http://127.0.0.1:" + server.getAddress().getPort() + "/example.invalid/webhook/token";
    }

    private BugReportNotification notification(String content) {
        return new BugReportNotification(UUID.randomUUID(), BugReportSource.USER, content, "1.0.0",
            BugReportPlatform.ANDROID);
    }

    @Test
    void notify_sendsAllowedMentionsEmptyAndSuppressEmbeds() {
        adapterFor(liveWebhookUrl()).notify(notification("앱이 멈춰요"));

        JsonNode body = new ObjectMapper().readTree(requestBody.get());
        assertThat(body.get("content").asString()).contains("앱이 멈춰요");
        assertThat(body.get("allowed_mentions").get("parse").isArray()).isTrue();
        assertThat(body.get("allowed_mentions").get("parse").size()).isZero();
        assertThat(body.get("flags").asInt()).isEqualTo(4);
    }

    @Test
    void notify_serverError_doesNotThrow() {
        responseStatus = 500;

        assertThatCode(() -> adapterFor(liveWebhookUrl()).notify(notification("내용"))).doesNotThrowAnyException();
    }

    @Test
    void notify_failure_doesNotLogWebhookUrl() {
        // 닫힌 포트로 연결 실패를 일으킨다. 이때 예외 메시지에는 URL이 들어 있다
        String unreachableUrl = "http://127.0.0.1:1/example.invalid/webhook/token";

        adapterFor(unreachableUrl).notify(notification("내용"));

        assertThat(logAppender.list).isNotEmpty();
        assertThat(logAppender.list).allSatisfy(event -> {
            assertThat(event.getFormattedMessage()).doesNotContain("example.invalid/webhook");
            assertThat(event.getThrowableProxy()).isNull();
        });
    }

    @Test
    void notify_malformedWebhookUrl_doesNotThrowAndDoesNotLogValue() {
        String malformedUrl = "not a uri with spaces";

        assertThatCode(() -> adapterFor(malformedUrl).notify(notification("내용"))).doesNotThrowAnyException();

        assertThat(logAppender.list).isNotEmpty();
        assertThat(logAppender.list).allSatisfy(event -> {
            assertThat(event.getFormattedMessage()).doesNotContain("not a uri");
            assertThat(event.getThrowableProxy()).isNull();
        });
    }

    @Test
    void notify_contentWithEveryone_staysEscapedAndMentionsBlocked() {
        adapterFor(liveWebhookUrl()).notify(notification("@everyone <@123> `코드`"));

        JsonNode body = new ObjectMapper().readTree(requestBody.get());
        assertThat(body.get("content").asString()).contains("\\`코드\\`");
        assertThat(body.get("allowed_mentions").get("parse").size()).isZero();
    }

    @Test
    void constructor_requiresBugReportRestClientQualifier() {
        var parameter = DiscordBugReportNotificationAdapter.class.getConstructors()[0].getParameters()[0];

        Qualifier qualifier = parameter.getAnnotation(Qualifier.class);

        assertThat(parameter.getType()).isEqualTo(RestClient.class);
        assertThat(qualifier).isNotNull();
        assertThat(qualifier.value()).isEqualTo("bugReportRestClient");
    }

}
