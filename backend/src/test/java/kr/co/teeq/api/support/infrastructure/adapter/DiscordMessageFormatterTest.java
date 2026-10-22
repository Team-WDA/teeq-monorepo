package kr.co.teeq.api.support.infrastructure.adapter;

import static org.assertj.core.api.Assertions.assertThat;

import java.nio.charset.StandardCharsets;
import java.util.UUID;
import kr.co.teeq.api.support.core.constant.BugReportPlatform;
import kr.co.teeq.api.support.core.constant.BugReportSource;
import kr.co.teeq.api.support.core.port.BugReportNotification;
import org.junit.jupiter.api.Test;

class DiscordMessageFormatterTest {

    private static final String ADMIN_BASE_URL = "https://admin.example.invalid";

    private final DiscordMessageFormatter formatter = new DiscordMessageFormatter();

    private BugReportNotification notification(BugReportSource source, String content) {
        return new BugReportNotification(UUID.randomUUID(), source, content, "1.2.3", BugReportPlatform.ANDROID);
    }

    @Test
    void format_escapesMarkdown() {
        BugReportNotification notification = new BugReportNotification(UUID.randomUUID(), BugReportSource.USER,
            "`a` *b* _c_ ~d~ |e| >f [g](h)", "1_2*3", BugReportPlatform.IOS);

        String message = formatter.format(notification, ADMIN_BASE_URL);

        assertThat(message).contains("\\`a\\` \\*b\\* \\_c\\_ \\~d\\~ \\|e\\| \\>f \\[g\\]\\(h\\)");
        assertThat(message).contains("1\\_2\\*3");
    }

    @Test
    void format_escapesBackslashItself() {
        String message = formatter.format(notification(BugReportSource.USER, "\\*a\\*"), ADMIN_BASE_URL);

        assertThat(message).contains("\\\\\\*a\\\\\\*");
    }

    @Test
    void format_maskedLinkPayload_escapesEveryControlCharacter() {
        String message = formatter.format(
            notification(BugReportSource.USER, "\\[click\\](https://example.invalid/x)"), ADMIN_BASE_URL);

        assertThat(message).contains("\\\\\\[click\\\\\\]\\(https://example.invalid/x\\)");
    }

    @Test
    void format_emojiStraddlingExcerptCut_leavesNoLoneSurrogate() {
        String content = "가".repeat(99) + "😀" + "나".repeat(10);

        String message = formatter.format(notification(BugReportSource.USER, content), ADMIN_BASE_URL);

        assertThat(new String(message.getBytes(StandardCharsets.UTF_8), StandardCharsets.UTF_8)).isEqualTo(message);
        assertThat(message).contains("가".repeat(99) + "…");
    }

    @Test
    void format_replacesLineBreaksWithSpace() {
        String message = formatter.format(notification(BugReportSource.USER, "첫줄\n둘째줄\r\n셋째줄"), ADMIN_BASE_URL);

        assertThat(message).contains("첫줄 둘째줄 셋째줄");
    }

    @Test
    void format_truncatesExcerptAtOneHundredCharacters() {
        String message = formatter.format(notification(BugReportSource.USER, "가".repeat(150)), ADMIN_BASE_URL);

        assertThat(message).contains("가".repeat(100) + "…").doesNotContain("가".repeat(101));
    }

    @Test
    void format_neverExceedsTwoThousandCharacters() {
        BugReportNotification notification = new BugReportNotification(UUID.randomUUID(), BugReportSource.USER,
            "\\".repeat(5000), "\\".repeat(3000), BugReportPlatform.ANDROID);

        String message = formatter.format(notification, ADMIN_BASE_URL);

        assertThat(message.length()).isLessThanOrEqualTo(2000);
    }

    @Test
    void format_includesAdminLink() {
        UUID bugReportId = UUID.randomUUID();
        BugReportNotification notification = new BugReportNotification(bugReportId, BugReportSource.USER, "내용",
            "1.0.0", BugReportPlatform.ANDROID);

        String message = formatter.format(notification, ADMIN_BASE_URL + "/");

        assertThat(message).contains(ADMIN_BASE_URL + "/admin/bug-reports/" + bugReportId);
    }

    @Test
    void format_developerConsoleBadge() {
        assertThat(formatter.format(notification(BugReportSource.DEVELOPER_CONSOLE, "내용"), ADMIN_BASE_URL))
            .contains("[개발자 콘솔]");
        assertThat(formatter.format(notification(BugReportSource.USER, "내용"), ADMIN_BASE_URL))
            .contains("[일반]");
    }

}
