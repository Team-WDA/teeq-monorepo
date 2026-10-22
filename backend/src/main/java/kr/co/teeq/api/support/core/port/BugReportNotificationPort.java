package kr.co.teeq.api.support.core.port;

/**
 * 버그 제보 저장 사실을 외부 채널로 알리는 port.
 */
public interface BugReportNotificationPort {

    void notify(BugReportNotification notification);

}
