package kr.co.teeq.api.admin.support;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;

import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.member.core.principal.AuthenticatedAdmin;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.web.servlet.request.RequestPostProcessor;

/**
 * 로그인한 관리자 세션을 흉내 낸다. principal 형태는 실제 로그인 성공 시와 같다.
 */
public final class AdminTestAuthentication {

    public static final UUID ADMIN_ID = UUID.fromString("0199f5a0-1c2d-7e3f-8a4b-5c6d7e8f9a0b");

    private AdminTestAuthentication() {
    }

    public static RequestPostProcessor asAdmin() {
        AuthenticatedAdmin principal = new AuthenticatedAdmin(ADMIN_ID, "operator", "운영자");
        return authentication(UsernamePasswordAuthenticationToken.authenticated(
            principal, null, List.of(new SimpleGrantedAuthority("ROLE_ADMIN"))));
    }

}
