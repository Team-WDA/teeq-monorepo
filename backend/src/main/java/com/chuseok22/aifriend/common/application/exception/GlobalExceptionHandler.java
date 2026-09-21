package com.chuseok22.aifriend.common.application.exception;

import com.chuseok22.aifriend.common.core.exception.BusinessException;
import com.chuseok22.aifriend.common.core.exception.CommonErrorCode;
import com.chuseok22.aifriend.common.core.exception.ErrorCode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

/**
 * 모든 오류를 RFC 9457 ProblemDetail로 변환한다. 프레임워크 예외(검증 실패 등)는 부모 클래스가 처리한다.
 */
@RestControllerAdvice
public class GlobalExceptionHandler extends ResponseEntityExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);
    private static final String CODE_PROPERTY = "code";

    @ExceptionHandler(BusinessException.class)
    public ProblemDetail handleBusinessException(BusinessException exception) {
        ErrorCode errorCode = exception.getErrorCode();
        log.warn("Business exception: {}", errorCode.name());
        return toProblemDetail(errorCode);
    }

    @ExceptionHandler(Exception.class)
    public ProblemDetail handleUnexpectedException(Exception exception) {
        log.error("Unexpected exception", exception);
        return toProblemDetail(CommonErrorCode.INTERNAL_SERVER_ERROR);
    }

    private ProblemDetail toProblemDetail(ErrorCode errorCode) {
        ProblemDetail problemDetail = ProblemDetail.forStatusAndDetail(
            HttpStatusCode.valueOf(errorCode.httpStatus()), errorCode.message());
        problemDetail.setProperty(CODE_PROPERTY, errorCode.name());
        return problemDetail;
    }

}
