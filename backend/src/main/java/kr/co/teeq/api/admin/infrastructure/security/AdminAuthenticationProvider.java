package kr.co.teeq.api.admin.infrastructure.security;

import java.util.List;
import kr.co.teeq.api.member.core.principal.AuthenticatedAdmin;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;

/**
 * 관리자 체인 전용 인증 제공자. 비밀번호 검증은 상위 클래스에 맡기고, 성공 시 principal을 {@link AuthenticatedAdmin}으로 바꾼다.
 */
public class AdminAuthenticationProvider extends DaoAuthenticationProvider {

    public AdminAuthenticationProvider(AdminUserDetailsService adminUserDetailsService, PasswordEncoder passwordEncoder) {
        super(adminUserDetailsService);
        setPasswordEncoder(passwordEncoder);
    }

    // 세션에는 비밀번호 해시가 아니라 식별 정보만 남기고, 권한은 ROLE_ADMIN 하나만 준다
    @Override
    protected Authentication createSuccessAuthentication(Object principal, Authentication authentication,
        UserDetails user) {
        AdminUserDetails adminUserDetails = (AdminUserDetails) user;
        AuthenticatedAdmin authenticatedAdmin = new AuthenticatedAdmin(
            adminUserDetails.adminId(), adminUserDetails.username(), adminUserDetails.name());
        UsernamePasswordAuthenticationToken result = UsernamePasswordAuthenticationToken.authenticated(
            authenticatedAdmin, null, List.of(new SimpleGrantedAuthority(AdminUserDetails.ADMIN_AUTHORITY)));
        result.setDetails(authentication.getDetails());
        return result;
    }

}
