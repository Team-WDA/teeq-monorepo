package kr.co.teeq.api.support.application.dto.response;

import java.time.Instant;
import java.util.UUID;
import kr.co.teeq.api.support.core.constant.BugReportSource;
import kr.co.teeq.api.support.core.constant.BugReportStatus;

/**
 * 관리자 목록의 한 줄. 탈퇴한 회원의 제보도 이메일 그대로 담고 탈퇴 여부를 따로 알린다.
 */
public record BugReportSummaryResponse(
    UUID id,
    String contentPreview,
    BugReportStatus status,
    BugReportSource source,
    String memberEmail,
    boolean memberDeleted,
    Instant createdAt
) {

}
