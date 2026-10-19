package kr.co.teeq.api.admin.infrastructure.security;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.security.core.Authentication;
import org.springframework.security.web.authentication.AuthenticationSuccessHandler;

/**
 * 관리자 로그인 성공 시 세션 만료를 1시간으로 정하고 대시보드 홈으로 보낸다.
 */
public class AdminLoginSuccessHandler implements AuthenticationSuccessHandler {

    private static final int SESSION_TIMEOUT_SECONDS = 3600;

    private final String homePath;

    public AdminLoginSuccessHandler(String homePath) {
        this.homePath = homePath;
    }

    // 사용자 API는 세션을 쓰지 않으므로 전역 설정 대신 관리자 세션에만 만료 시간을 준다
    @Override
    public void onAuthenticationSuccess(HttpServletRequest request, HttpServletResponse response,
        Authentication authentication) throws IOException {
        request.getSession().setMaxInactiveInterval(SESSION_TIMEOUT_SECONDS);
        response.sendRedirect(request.getContextPath() + homePath);
    }

}
