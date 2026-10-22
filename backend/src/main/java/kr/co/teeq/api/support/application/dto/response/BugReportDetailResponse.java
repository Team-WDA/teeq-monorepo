package kr.co.teeq.api.support.application.dto.response;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.support.core.constant.BugReportPlatform;
import kr.co.teeq.api.support.core.constant.BugReportSource;
import kr.co.teeq.api.support.core.constant.BugReportStatus;

/**
 * 관리자 상세. 로그는 파싱한 목록이고(없으면 빈 목록), 용량 때문에 빠진 건수를 함께 담는다.
 */
public record BugReportDetailResponse(
    UUID id,
    String content,
    BugReportStatus status,
    BugReportSource source,
    Instant createdAt,
    String appVersion,
    BugReportPlatform platform,
    String osVersion,
    String deviceModel,
    UUID memberId,
    String memberEmail,
    String memberNickname,
    boolean memberDeleted,
    List<BugReportImageResponse> images,
    List<BugReportErrorLogResponse> errorLogs,
    List<BugReportNetworkLogResponse> networkLogs,
    int omittedErrorLogCount,
    int omittedNetworkLogCount
) {

}
