package kr.co.teeq.api.common.application.exception;

import io.swagger.v3.oas.annotations.media.Schema;
import kr.co.teeq.api.common.core.exception.ErrorCode;

/**
 * 에러 응답 본문. 필드는 두 개뿐이며 HTTP 상태는 응답 상태 줄에만 담는다.
 * Spring의 {@code org.springframework.web.ErrorResponse}와 이름이 같으므로 import를 혼동하지 않는다.
 */
public record ErrorResponse(
    @Schema(description = "에러 코드. `ErrorCode` enum 상수 이름이며 클라이언트는 이 값으로 분기한다.", example = "DUPLICATE_NICKNAME")
    String errorCode,

    @Schema(description = "사용자에게 보여 줄 수 있는 한국어 메시지. 입력 검증 실패(`INVALID_REQUEST`)는 위반 사유가 담긴다.", example = "이미 사용 중인 닉네임입니다.")
    String errorMessage
) {

    public static ErrorResponse of(ErrorCode errorCode) {
        return new ErrorResponse(errorCode.name(), errorCode.message());
    }

    public static ErrorResponse of(ErrorCode errorCode, String errorMessage) {
        return new ErrorResponse(errorCode.name(), errorMessage);
    }

}
