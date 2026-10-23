package kr.co.teeq.api.auth.infrastructure.config;

public final class SecurityPaths {

    // 인증 없이 열어 둘 경로. /error는 필터 체인 밖으로 빠져나온 예외의 ERROR 디스패치도 인가 대상이라,
    // 열지 않으면 Boot의 500 응답 본문 대신 401로 바뀐다
    public static final String[] PUBLIC_PATHS = {
        "/api/auth/refresh",
        "/api/auth/social-login",
        "/api/auth/social-signup",
        "/api/members/nickname-availability",
        "/api/app-versions/check",
        "/actuator/health",
        "/docs/swagger",
        "/docs/swagger-ui/**",
        "/swagger-ui/**",
        "/v3/api-docs/**",
        "/error"
    };

    private SecurityPaths() {
    }

}
