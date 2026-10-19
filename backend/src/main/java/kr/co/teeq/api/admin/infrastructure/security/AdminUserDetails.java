package kr.co.teeq.api.admin.infrastructure.security;

import java.util.Collection;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.member.core.entity.Admin;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

/**
 * 비밀번호 검증 동안만 쓰는 관리자 정보. 인증이 끝나면 principal은 {@code AuthenticatedAdmin}으로 바뀐다.
 */
public record AdminUserDetails(UUID adminId, String username, String password, String name) implements UserDetails {

    static final String ADMIN_AUTHORITY = "ROLE_ADMIN";

    public static AdminUserDetails from(Admin admin) {
        return new AdminUserDetails(admin.getId(), admin.getUsername(), admin.getPassword(), admin.getName());
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return List.of(new SimpleGrantedAuthority(ADMIN_AUTHORITY));
    }

    @Override
    public String getPassword() {
        return password;
    }

    @Override
    public String getUsername() {
        return username;
    }

    // record 기본 toString이 비밀번호 해시를 로그에 남기지 않게 한다
    @Override
    public String toString() {
        return "AdminUserDetails[adminId=" + adminId + ", username=" + username + "]";
    }

}
