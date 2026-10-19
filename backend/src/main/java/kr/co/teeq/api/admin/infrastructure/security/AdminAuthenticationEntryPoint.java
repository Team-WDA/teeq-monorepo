package kr.co.teeq.api.admin.infrastructure.security;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import kr.co.teeq.api.common.application.exception.ErrorResponse;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.authentication.LoginUrlAuthenticationEntryPoint;
import org.springframework.security.web.servlet.util.matcher.PathPatternRequestMatcher;
import org.springframework.security.web.util.matcher.RequestMatcher;
import tools.jackson.databind.ObjectMapper;

/**
 * 관리자 체인의 미인증 응답. 요청 종류에 따라 htmx 리다이렉트, REST JSON, 로그인 화면 302 중 하나를 고른다.
 */
public class AdminAuthenticationEntryPoint implements AuthenticationEntryPoint {

    static final String HTMX_REQUEST_HEADER = "HX-Request";
    static final String HTMX_REDIRECT_HEADER = "HX-Redirect";

    private static final RequestMatcher REST_REQUEST_MATCHER =
        PathPatternRequestMatcher.withDefaults().matcher("/api/admin/**");

    private final ObjectMapper objectMapper;
    private final String loginPath;
    private final LoginUrlAuthenticationEntryPoint loginPageEntryPoint;

    public AdminAuthenticationEntryPoint(ObjectMapper objectMapper, String loginPath) {
        this.objectMapper = objectMapper;
        this.loginPath = loginPath;
        this.loginPageEntryPoint = new LoginUrlAuthenticationEntryPoint(loginPath);
    }

    @Override
    public void commence(HttpServletRequest request, HttpServletResponse response,
        AuthenticationException authException) throws IOException, ServletException {
        // 세션이 만료된 htmx 요청이 로그인 HTML을 화면 조각에 끼워 넣지 않고 페이지 전체를 이동시키게 한다
        if (isHtmxRequest(request)) {
            respondHtmxRedirect(request, response, loginPath);
            return;
        }
        if (isRestRequest(request)) {
            response.setStatus(ErrorCode.UNAUTHENTICATED.httpStatus());
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write(objectMapper.writeValueAsString(ErrorResponse.of(ErrorCode.UNAUTHENTICATED)));
            return;
        }
        loginPageEntryPoint.commence(request, response, authException);
    }

    static boolean isHtmxRequest(HttpServletRequest request) {
        return "true".equals(request.getHeader(HTMX_REQUEST_HEADER));
    }

    static boolean isRestRequest(HttpServletRequest request) {
        return REST_REQUEST_MATCHER.matches(request);
    }

    static void respondHtmxRedirect(HttpServletRequest request, HttpServletResponse response, String loginPath) {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setHeader(HTMX_REDIRECT_HEADER, request.getContextPath() + loginPath);
    }

}
