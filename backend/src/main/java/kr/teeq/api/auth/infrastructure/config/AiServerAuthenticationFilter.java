package kr.teeq.api.auth.infrastructure.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.List;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

// AI 서버가 보내는 공유 헤더를 검증한다. 불일치·없음은 인증을 두지 않고 넘겨 엔트리 포인트가 401로 응답하게 한다
public class AiServerAuthenticationFilter extends OncePerRequestFilter {

    private static final String AI_SERVER_PRINCIPAL = "ai-server";
    private static final String AI_SERVER_ROLE = "ROLE_AI_SERVER";

    private final String headerName;
    private final byte[] expectedHeaderValue;

    public AiServerAuthenticationFilter(String headerName, String headerValue) {
        this.headerName = headerName;
        this.expectedHeaderValue = headerValue.getBytes(StandardCharsets.UTF_8);
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
        throws ServletException, IOException {
        String actualHeaderValue = request.getHeader(headerName);
        if (actualHeaderValue != null
            && MessageDigest.isEqual(expectedHeaderValue, actualHeaderValue.getBytes(StandardCharsets.UTF_8))) {
            SecurityContextHolder.getContext().setAuthentication(new UsernamePasswordAuthenticationToken(
                AI_SERVER_PRINCIPAL, null, List.of(new SimpleGrantedAuthority(AI_SERVER_ROLE))));
        }
        filterChain.doFilter(request, response);
    }

}
