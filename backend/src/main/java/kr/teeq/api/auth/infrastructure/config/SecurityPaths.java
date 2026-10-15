package kr.teeq.api.auth.infrastructure.config;

public final class SecurityPaths {

    // 인증 없이 열어 둘 경로. /error는 필터 체인 밖으로 빠져나온 예외의 ERROR 디스패치도 인가 대상이라,
    // 열지 않으면 Boot의 500 응답 본문 대신 401로 바뀐다
    public static final String[] PUBLIC_PATHS = {
        "/api/auth/login",
        "/api/auth/refresh",
        "/api/members/nickname-availability",
        "/actuator/health",
        "/error"
    };

    // 가입은 POST만 연다. 같은 경로의 다른 메서드는 인증이 필요하다
    public static final String[] PUBLIC_POST_PATHS = {
        "/api/members"
    };

    private SecurityPaths() {
    }

}
