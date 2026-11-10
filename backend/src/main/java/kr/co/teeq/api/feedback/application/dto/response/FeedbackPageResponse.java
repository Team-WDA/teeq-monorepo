package kr.co.teeq.api.feedback.application.dto.response;

import java.util.List;

public record FeedbackPageResponse(
    List<FeedbackListItemResponse> items,
    int page,
    int size,
    long totalElements
) {

}
