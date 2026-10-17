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
    SOCIAL_TOKEN_INVALID(401, "소셜 로그인 인증 정보가 올바르지 않습니다."),
    SOCIAL_SERVER_UNAVAILABLE(502, "소셜 로그인 서버와 통신할 수 없습니다."),
    SOCIAL_SIGNUP_REQUIRED(409, "소셜 로그인 가입에 필요한 정보가 없습니다."),
    LOGIN_METHOD_MISMATCH(401, "가입한 로그인 방식이 다릅니다."),

    // 통화
    CALL_LIMIT_INSUFFICIENT(403, "오늘 사용할 수 있는 통화 시간이 부족합니다."),
    CALL_SERVICE_LIMIT_EXCEEDED(403, "지금은 통화를 이용할 수 없습니다."),
    CALL_BONUS_NOT_FOUND(404, "추가 통화 시간을 찾을 수 없습니다."),
    CALL_ALREADY_IN_PROGRESS(409, "이미 진행 중인 통화가 있습니다."),
    AI_SERVER_UNAVAILABLE(502, "AI 서버와 통신할 수 없습니다."),
    CALL_SESSION_NOT_FOUND(404, "통화 세션을 찾을 수 없습니다."),

    // 피드백
    CALL_NOT_FEEDBACKABLE(409, "피드백을 남길 수 없는 통화입니다."),
    FEEDBACK_ALREADY_SUBMITTED(409, "이미 제출한 피드백입니다."),
    REQUIRED_FEEDBACK_NOT_SUBMITTED(409, "필수 피드백을 먼저 제출해야 합니다."),
    DETAILED_FEEDBACK_NOT_INVITED(409, "상세 피드백 대상이 아닌 통화입니다."),
    INVALID_FEEDBACK_ANSWER(400, "피드백 답변이 올바르지 않습니다."),

    // 온보딩
    ONBOARDING_ANSWER_INCOMPLETE(400, "온보딩 질문에 모두 답해야 합니다."),
    ONBOARDING_ANSWER_DUPLICATED(400, "온보딩 답변에 중복된 질문 또는 선택지가 있습니다."),
    INVALID_ONBOARDING_OPTION(400, "질문에 맞지 않거나 선택 가능한 개수를 넘은 선택지입니다."),

    // AI 캐릭터
    AI_CHARACTER_NOT_FOUND(404, "AI 캐릭터를 찾을 수 없습니다."),

    // 프로필 사진
    PROFILE_IMAGE_INVALID(400, "프로필 사진으로 사용할 수 없는 파일입니다. JPEG, PNG, WebP 이미지만 올릴 수 있습니다."),
    PROFILE_IMAGE_TOO_LARGE(413, "프로필 사진은 5MB 이하만 올릴 수 있습니다."),

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
