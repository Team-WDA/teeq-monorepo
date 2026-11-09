package kr.co.teeq.api.call.application.dto.response;

import java.time.Instant;
import java.util.UUID;
import kr.co.teeq.api.call.core.constant.CallStatus;
import kr.co.teeq.api.call.core.constant.EndReason;

/**
 * 관리자 통화 목록의 한 건. callSessionId는 세션 생성 전(PENDING, FAILED)에는 null이다.
 */
public record CallHistoryItemResponse(
    String callSessionId,
    UUID memberId,
    String memberNickname,
    String memberEmail,
    Instant startedAt,
    int durationSeconds,
    CallStatus status,
    EndReason endReason,
    String llmModel
) {

}
