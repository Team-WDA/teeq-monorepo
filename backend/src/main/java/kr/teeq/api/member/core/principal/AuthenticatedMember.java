package kr.teeq.api.member.core.principal;

import kr.teeq.api.member.core.entity.Member;

/**
 * 인증된 요청의 principal. JWT 필터가 요청마다 조회한 회원을 담는다.
 * open-in-view가 꺼져 있어 분리 상태의 엔티티이므로, 수정이 필요하면 서비스에서 id로 다시 조회한다.
 */
public record AuthenticatedMember(Member member) {

}
