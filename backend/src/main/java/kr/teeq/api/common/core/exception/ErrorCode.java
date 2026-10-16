package kr.teeq.api.common.core.exception;

/**
 * 서비스 전체의 에러 코드. enum 하나로 관리하고, 도메인 코드는 도메인별 주석 섹션으로 추가한다.
 * 클라이언트는 enum 상수 이름({@link #name()})으로 분기한다.
 */
public enum ErrorCode {

    // 공통
    INVALID_REQUEST(400, "잘못된 요청입니다."),
    MALFORMED_REQUEST_BODY(400, "요청 본문을 읽을 수 없습니다."),
    RESOURCE_NOT_FOUND(404, "요청한 리소스를 찾을 수 없습니다."),
    METHOD_NOT_ALLOWED(405, "지원하지 않는 HTTP 메서드입니다."),
    UNSUPPORTED_MEDIA_TYPE(415, "지원하지 않는 미디어 타입입니다."),
    STATE_CONFLICT(409, "현재 상태에서는 처리할 수 없습니다."),
    INTERNAL_SERVER_ERROR(500, "서버 내부 오류가 발생했습니다."),

    // 인증과 계정
    UNAUTHENTICATED(401, "인증이 필요합니다."),
    EXPIRED_TOKEN(401, "토큰이 만료되었습니다."),
    INVALID_CREDENTIALS(401, "이메일 또는 비밀번호가 올바르지 않습니다."),
    INVALID_REFRESH_TOKEN(401, "유효하지 않은 리프레시 토큰입니다."),
    ACCESS_DENIED(403, "접근 권한이 없습니다."),
    DUPLICATE_EMAIL(409, "이미 사용 중인 이메일입니다."),
    DUPLICATE_NICKNAME(409, "이미 사용 중인 닉네임입니다."),
    INVALID_CURRENT_PASSWORD(400, "현재 비밀번호가 올바르지 않습니다."),
    MEMBER_NOT_FOUND(404, "회원을 찾을 수 없습니다."),

    // 동적 설정
    SETTING_CONFIG_NOT_FOUND(404, "설정을 찾을 수 없습니다."),
    INVALID_SETTING_VALUE(400, "설정 값이 올바르지 않습니다.");

    private final int httpStatus;
    private final String message;

    ErrorCode(int httpStatus, String message) {
        this.httpStatus = httpStatus;
        this.message = message;
    }

    public int httpStatus() {
        return httpStatus;
    }

    public String message() {
        return message;
    }

}
