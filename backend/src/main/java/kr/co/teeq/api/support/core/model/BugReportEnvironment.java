package kr.co.teeq.api.support.core.model;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import kr.co.teeq.api.support.core.constant.BugReportPlatform;

/**
 * 버그 제보 시점의 앱·기기 환경.
 */
@Embeddable
public record BugReportEnvironment(
    @Column(nullable = false, length = 50) String appVersion,
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 10) BugReportPlatform platform,
    @Column(nullable = false, length = 100) String osVersion,
    @Column(nullable = false, length = 100) String deviceModel
) {
}
