package kr.co.teeq.api.call.application.dto.response;

import java.util.List;

public record CallHistoryPageResponse(
    List<CallHistoryItemResponse> content,
    int page,
    int size,
    long totalElements
) {

}
