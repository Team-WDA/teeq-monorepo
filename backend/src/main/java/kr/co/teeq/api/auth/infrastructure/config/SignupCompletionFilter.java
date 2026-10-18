package kr.co.teeq.api.auth.infrastructure.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import kr.co.teeq.api.common.application.exception.ErrorResponse;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.principal.AuthenticatedMember;
import org.springframework.http.HttpMethod;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.servlet.util.matcher.PathPatternRequestMatcher;
import org.springframework.security.web.util.matcher.OrRequestMatcher;
import org.springframework.security.web.util.matcher.RequestMatcher;
import org.springframework.web.filter.OncePerRequestFilter;
import tools.jackson.databind.ObjectMapper;

// JWT 필터 뒤에서 가입 미완료 회원(닉네임 NULL)을 공개 경로와 허용 목록 밖에서 403으로 막는다.
// 인증이 없거나 가입을 마친 회원의 요청은 건드리지 않는다(401은 entry point가 맡는다)
public class SignupCompletionFilter extends OncePerRequestFilter {

    private final ObjectMapper objectMapper;
    private final RequestMatcher allowedRequestMatcher;

    public SignupCompletionFilter(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
        this.allowedRequestMatcher = buildAllowedRequestMatcher();
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
        FilterChain filterChain) throws ServletException, IOException {
        if (isSignupIncompleteMember() && !allowedRequestMatcher.matches(request)) {
            response.setStatus(ErrorCode.SIGNUP_NOT_COMPLETED.httpStatus());
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter()
                .write(objectMapper.writeValueAsString(ErrorResponse.of(ErrorCode.SIGNUP_NOT_COMPLETED)));
            return;
        }
        filterChain.doFilter(request, response);
    }

    private boolean isSignupIncompleteMember() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication != null
            && authentication.getPrincipal() instanceof AuthenticatedMember authenticatedMember
            && !authenticatedMember.member().isSignupCompleted();
    }

    // 공개 경로는 SecurityConfig의 permitAll과 같은 기준(메서드 무관, PUBLIC_POST_PATHS는 POST만)으로 맞춘다
    private static RequestMatcher buildAllowedRequestMatcher() {
        List<RequestMatcher> matchers = new ArrayList<>();
        Arrays.stream(SecurityPaths.PUBLIC_PATHS)
            .map(path -> PathPatternRequestMatcher.withDefaults().matcher(path))
            .forEach(matchers::add);
        Arrays.stream(SecurityPaths.PUBLIC_POST_PATHS)
            .map(path -> PathPatternRequestMatcher.withDefaults().matcher(HttpMethod.POST, path))
            .forEach(matchers::add);
        matchers.addAll(SecurityPaths.SIGNUP_INCOMPLETE_ALLOWED_REQUESTS);
        return new OrRequestMatcher(matchers);
    }

}
