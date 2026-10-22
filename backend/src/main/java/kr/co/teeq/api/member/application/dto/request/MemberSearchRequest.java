package kr.co.teeq.api.member.application.dto.request;

import kr.co.teeq.api.member.core.constant.LoginType;

/**
 * 관리자 회원 목록 검색 조건. 값이 null이면 그 조건은 적용하지 않는다.
 */
public record MemberSearchRequest(
    String keyword,
    LoginType loginType,
    Boolean signupCompleted
) {

}
