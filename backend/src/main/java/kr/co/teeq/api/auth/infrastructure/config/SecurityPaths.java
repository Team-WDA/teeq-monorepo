package kr.co.teeq.api.auth.infrastructure.config;

import java.util.List;
import org.springframework.http.HttpMethod;
import org.springframework.security.web.servlet.util.matcher.PathPatternRequestMatcher;
import org.springframework.security.web.util.matcher.RequestMatcher;

public final class SecurityPaths {

    // 인증 없이 열어 둘 경로. /error는 필터 체인 밖으로 빠져나온 예외의 ERROR 디스패치도 인가 대상이라,
    // 열지 않으면 Boot의 500 응답 본문 대신 401로 바뀐다
    public static final String[] PUBLIC_PATHS = {
        "/api/auth/login",
        "/api/auth/refresh",
        "/api/auth/social-login",
        "/api/members/nickname-availability",
        "/actuator/health",
        "/docs/swagger",
        "/docs/swagger-ui/**",
        "/swagger-ui/**",
        "/v3/api-docs/**",
        "/error"
    };

    // 가입은 POST만 연다. 같은 경로의 다른 메서드는 인증이 필요하다
    public static final String[] PUBLIC_POST_PATHS = {
        "/api/members"
    };

    // 가입 미완료 회원(닉네임 NULL)이 공개 경로 밖에서 호출할 수 있는 요청(메서드와 경로 쌍).
    // 그 외 인증 경로는 SignupCompletionFilter가 403으로 막는다. 토큰 재발급과 닉네임 확인은 공개 경로라 여기 없다
    public static final List<RequestMatcher> SIGNUP_INCOMPLETE_ALLOWED_REQUESTS = List.of(
        PathPatternRequestMatcher.withDefaults().matcher(HttpMethod.GET, "/api/members/me"),
        PathPatternRequestMatcher.withDefaults().matcher(HttpMethod.POST, "/api/members/me/signup-completion"),
        PathPatternRequestMatcher.withDefaults().matcher(HttpMethod.POST, "/api/auth/logout"),
        PathPatternRequestMatcher.withDefaults().matcher(HttpMethod.DELETE, "/api/members/me")
    );

    private SecurityPaths() {
    }

}
