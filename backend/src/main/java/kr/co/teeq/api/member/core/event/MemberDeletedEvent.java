package kr.co.teeq.api.member.core.event;

import java.util.UUID;

/**
 * 회원이 삭제(soft delete)되었음을 알리는 이벤트. 각 도메인의 삭제 핸들러가 같은 트랜잭션에서 받아 자기 데이터를 정리한다.
 */
public record MemberDeletedEvent(UUID memberId) {

}
