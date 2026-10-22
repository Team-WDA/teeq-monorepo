package kr.co.teeq.api.support.infrastructure.adapter;

import kr.co.teeq.api.support.core.constant.BugReportSource;
import kr.co.teeq.api.support.core.port.BugReportNotification;
import org.springframework.stereotype.Component;

/**
 * 제보 알림을 Discord 메시지 한 건(2000자 이하)으로 만든다.
 */
@Component
class DiscordMessageFormatter {

    private static final int EXCERPT_MAX_LENGTH = 100;
    private static final int APP_VERSION_MAX_LENGTH = 50;
    private static final int MESSAGE_MAX_LENGTH = 2000;
    private static final String MARKDOWN_CHARACTERS = "\\`*_~|>[]()";

    String format(BugReportNotification notification, String adminBaseUrl) {
        String message = "%s 새 버그 제보%n> %s%n앱 버전: %s / 플랫폼: %s%n%s/admin/bug-reports/%s".formatted(
                toBadge(notification.source()),
                escape(toExcerpt(notification.content())),
                escape(truncate(notification.appVersion(), APP_VERSION_MAX_LENGTH)),
                escape(notification.platform().name()),
                stripTrailingSlash(adminBaseUrl),
                notification.bugReportId());
        return truncate(message, MESSAGE_MAX_LENGTH);
    }

    private String toBadge(BugReportSource source) {
        return source == BugReportSource.DEVELOPER_CONSOLE ? "[개발자 콘솔]" : "[일반]";
    }

    // 인용문(> )이 한 줄로 유지되도록 개행을 공백으로 바꾼다
    private String toExcerpt(String content) {
        String singleLine = content.replaceAll("\\s*[\\r\\n]+\\s*", " ").strip();
        if (singleLine.length() <= EXCERPT_MAX_LENGTH) {
            return singleLine;
        }
        return truncate(singleLine, EXCERPT_MAX_LENGTH) + "…";
    }

    private String escape(String text) {
        StringBuilder escaped = new StringBuilder(text.length());
        for (char character : text.toCharArray()) {
            if (MARKDOWN_CHARACTERS.indexOf(character) >= 0) {
                escaped.append('\\');
            }
            escaped.append(character);
        }
        return escaped.toString();
    }

    // 서로게이트 쌍(이모지 등)의 중간에서 자르지 않는다
    private String truncate(String text, int maxLength) {
        if (text.length() <= maxLength) {
            return text;
        }
        int end = Character.isHighSurrogate(text.charAt(maxLength - 1)) ? maxLength - 1 : maxLength;
        return text.substring(0, end);
    }

    private String stripTrailingSlash(String url) {
        return url.endsWith("/") ? url.substring(0, url.length() - 1) : url;
    }

}
