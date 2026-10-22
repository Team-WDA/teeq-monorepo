package kr.co.teeq.api.member.core.constant;

/**
 * 관리자 역할. SUPER_ADMIN은 ADMIN의 권한을 모두 포함한다(포함 관계는 보안 설정의 RoleHierarchy가 정한다).
 */
public enum AdminRole {

    SUPER_ADMIN,
    ADMIN;

    // Spring Security 권한 문자열
    public String authority() {
        return "ROLE_" + name();
    }

}
