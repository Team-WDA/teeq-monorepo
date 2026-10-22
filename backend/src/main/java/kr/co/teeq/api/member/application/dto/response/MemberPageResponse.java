package kr.co.teeq.api.member.application.dto.response;

import java.util.List;

public record MemberPageResponse(
    List<MemberSummaryResponse> members,
    int page,
    int size,
    long totalElements
) {

}
