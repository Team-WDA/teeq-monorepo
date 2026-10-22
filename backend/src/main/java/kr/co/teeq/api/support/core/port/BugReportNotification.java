package kr.co.teeq.api.support.core.port;

import java.util.UUID;
import kr.co.teeq.api.support.core.constant.BugReportPlatform;
import kr.co.teeq.api.support.core.constant.BugReportSource;

/**
 * 제보가 저장된 뒤 개발자에게 알릴 때 필요한 값. 로그와 이미지는 알림에 싣지 않는다.
 */
public record BugReportNotification(
    UUID bugReportId,
    BugReportSource source,
    String content,
    String appVersion,
    BugReportPlatform platform
) {

}
