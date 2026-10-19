package kr.co.teeq.api.member.core.principal;

import java.util.UUID;

/**
 * 관리자 세션의 principal. 엔티티가 아니라 식별 정보만 담는다.
 */
public record AuthenticatedAdmin(UUID adminId, String username, String name) {

}
