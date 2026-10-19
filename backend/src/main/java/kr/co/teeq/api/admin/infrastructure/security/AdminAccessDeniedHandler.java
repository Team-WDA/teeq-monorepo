package kr.co.teeq.api.admin.infrastructure.security;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import kr.co.teeq.api.common.application.exception.ErrorResponse;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.security.web.csrf.MissingCsrfTokenException;
import tools.jackson.databind.ObjectMapper;

/**
 * 관리자 체인의 접근 거부 응답. 이 체인은 Admin만 인증하므로 실제로는 CSRF 실패가 대부분이다.
 */
public class AdminAccessDeniedHandler implements AccessDeniedHandler {

    private final ObjectMapper objectMapper;
    private final String loginPath;

    public AdminAccessDeniedHandler(ObjectMapper objectMapper, String loginPath) {
        this.objectMapper = objectMapper;
        this.loginPath = loginPath;
    }

    @Override
    public void handle(HttpServletRequest request, HttpServletResponse response,
        AccessDeniedException accessDeniedException) throws IOException {
        // 세션이 만료되면 저장된 CSRF 토큰도 사라진다. 화면 요청은 403 JSON 대신 로그인 화면으로 보낸다
        if (accessDeniedException instanceof MissingCsrfTokenException
            && !AdminAuthenticationEntryPoint.isRestRequest(request)) {
            if (AdminAuthenticationEntryPoint.isHtmxRequest(request)) {
                AdminAuthenticationEntryPoint.respondHtmxRedirect(request, response, loginPath);
                return;
            }
            response.sendRedirect(request.getContextPath() + loginPath);
            return;
        }
        response.setStatus(ErrorCode.ACCESS_DENIED.httpStatus());
        response.setContentType("application/json;charset=UTF-8");
        response.getWriter().write(objectMapper.writeValueAsString(ErrorResponse.of(ErrorCode.ACCESS_DENIED)));
    }

}
