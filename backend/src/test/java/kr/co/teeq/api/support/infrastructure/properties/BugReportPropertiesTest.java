package kr.co.teeq.api.support.infrastructure.properties;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;

class BugReportPropertiesTest {

    private static final String WEBHOOK_URL = "https://example.invalid/webhook/secret-token";
    private static final String ADMIN_BASE_URL = "https://admin.example.invalid";

    @Test
    void constructor_validValues_doesNotThrow() {
        assertThatCode(() -> new BugReportProperties(new BugReportProperties.Discord(WEBHOOK_URL), ADMIN_BASE_URL))
            .doesNotThrowAnyException();
    }

    @Test
    void constructor_missingDiscordBlock_throwsIllegalStateException() {
        assertThatThrownBy(() -> new BugReportProperties(null, ADMIN_BASE_URL))
            .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void constructor_blankWebhookUrl_throwsWithoutValue() {
        assertThatThrownBy(() -> new BugReportProperties(new BugReportProperties.Discord(" "), ADMIN_BASE_URL))
            .isInstanceOf(IllegalStateException.class)
            .satisfies(exception -> assertThat(exception.getMessage())
                .doesNotContain(ADMIN_BASE_URL)
                .doesNotContain(WEBHOOK_URL));
    }

    @Test
    void constructor_blankAdminBaseUrl_throwsWithoutValue() {
        assertThatThrownBy(() -> new BugReportProperties(new BugReportProperties.Discord(WEBHOOK_URL), ""))
            .isInstanceOf(IllegalStateException.class)
            .satisfies(exception -> assertThat(exception.getMessage()).doesNotContain(WEBHOOK_URL));
    }

}
