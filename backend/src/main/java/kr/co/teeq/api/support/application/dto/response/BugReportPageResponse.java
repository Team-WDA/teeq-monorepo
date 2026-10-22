package kr.co.teeq.api.support.application.dto.response;

import java.util.List;

public record BugReportPageResponse(
    List<BugReportSummaryResponse> items,
    int page,
    int size,
    long totalElements
) {

}
