package kr.co.teeq.api.feedback.application.dto.response;

import java.time.Instant;
import java.util.UUID;
import kr.co.teeq.api.feedback.core.constant.RevisitIntention;

/**
 * 관리자 피드백 목록의 한 줄. 필수 피드백 기준으로 통화 하나가 한 줄이다. 통화 세션 ID는 없을 수 있다.
 */
public record FeedbackListItemResponse(
    String callSessionId,
    UUID memberId,
    String memberNickname,
    String memberEmail,
    Instant callStartedAt,
    int rating,
    RevisitIntention revisitIntention,
    boolean detailedSubmitted
) {

}
