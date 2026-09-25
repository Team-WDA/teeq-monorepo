package kr.teeq.api.common.application.exception;

import static org.assertj.core.api.Assertions.assertThat;

import kr.teeq.api.common.core.exception.BusinessException;
import kr.teeq.api.common.core.exception.CommonErrorCode;
import kr.teeq.api.common.core.exception.ErrorCode;
import org.junit.jupiter.api.Test;
import org.springframework.http.ProblemDetail;

class GlobalExceptionHandlerTest {

    private final GlobalExceptionHandler handler = new GlobalExceptionHandler();

    @Test
    void handleBusinessException_mapsErrorCodeToProblemDetail() {
        BusinessException exception = new BusinessException(SampleErrorCode.SAMPLE_NOT_FOUND);

        ProblemDetail problemDetail = handler.handleBusinessException(exception);

        assertThat(problemDetail.getStatus()).isEqualTo(404);
        assertThat(problemDetail.getDetail()).isEqualTo("샘플을 찾을 수 없습니다.");
        assertThat(problemDetail.getProperties()).containsEntry("code", "SAMPLE_NOT_FOUND");
    }

    @Test
    void handleUnexpectedException_hidesInternalMessage() {
        Exception exception = new IllegalStateException("jdbc:postgresql://internal-host/secret-db");

        ProblemDetail problemDetail = handler.handleUnexpectedException(exception);

        assertThat(problemDetail.getStatus()).isEqualTo(500);
        assertThat(problemDetail.getDetail()).isEqualTo(CommonErrorCode.INTERNAL_SERVER_ERROR.message());
        assertThat(problemDetail.getDetail()).doesNotContain("internal-host");
        assertThat(problemDetail.getProperties()).containsEntry("code", "INTERNAL_SERVER_ERROR");
    }

    private enum SampleErrorCode implements ErrorCode {

        SAMPLE_NOT_FOUND(404, "샘플을 찾을 수 없습니다.");

        private final int httpStatus;
        private final String message;

        SampleErrorCode(int httpStatus, String message) {
            this.httpStatus = httpStatus;
            this.message = message;
        }

        @Override
        public int httpStatus() {
            return httpStatus;
        }

        @Override
        public String message() {
            return message;
        }

    }

}
