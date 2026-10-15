package kr.teeq.api.common.application.exception;

import kr.teeq.api.common.core.exception.ErrorCode;

/**
 * 에러 응답 본문. 필드는 두 개뿐이며 HTTP 상태는 응답 상태 줄에만 담는다.
 * Spring의 {@code org.springframework.web.ErrorResponse}와 이름이 같으므로 import를 혼동하지 않는다.
 */
public record ErrorResponse(String errorCode, String errorMessage) {

    public static ErrorResponse of(ErrorCode errorCode) {
        return new ErrorResponse(errorCode.name(), errorCode.message());
    }

    public static ErrorResponse of(ErrorCode errorCode, String errorMessage) {
        return new ErrorResponse(errorCode.name(), errorMessage);
    }

}
