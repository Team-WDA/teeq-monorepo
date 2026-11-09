package kr.co.teeq.api.admin.application.dto.response;

import kr.co.teeq.api.call.application.dto.response.CallHistoryItemResponse;

/**
 * 관리자 통화 목록의 한 행. 템플릿이 문자열만 읽도록 라벨을 미리 계산해 담는다.
 */
public record AdminCallRowView(
    CallHistoryItemResponse call,
    String statusLabel,
    String endReasonLabel
) {

}
