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
    INTERNAL_SERVER_ERROR(500, "서버 내부 오류가 발생했습니다.");

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
