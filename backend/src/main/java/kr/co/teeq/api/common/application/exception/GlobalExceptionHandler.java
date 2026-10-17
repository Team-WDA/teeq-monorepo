package kr.co.teeq.api.common.application.exception;

import jakarta.validation.ConstraintViolationException;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.HttpMediaTypeNotSupportedException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.HandlerMethodValidationException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.multipart.MultipartException;
import org.springframework.web.multipart.support.MissingServletRequestPartException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

/**
 * 모든 오류를 {@link ErrorResponse}로 변환한다. {@code ResponseEntityExceptionHandler}는 상속하지 않는다
 * (ProblemDetail 본문이 나오지 않게 하기 위함).
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(CustomException.class)
    public ResponseEntity<ErrorResponse> handleCustomException(CustomException exception) {
        ErrorCode errorCode = exception.getErrorCode();
        if (errorCode.httpStatus() >= 500) {
            log.error("Custom exception: {}", errorCode.name(), exception);
        } else {
            log.warn("Custom exception: {}", errorCode.name());
        }
        return toResponse(ErrorResponse.of(errorCode), errorCode);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleMethodArgumentNotValid(MethodArgumentNotValidException exception) {
        String message = exception.getBindingResult().getFieldErrors().stream()
            .findFirst()
            .map(fieldError -> fieldError.getDefaultMessage())
            .orElse(ErrorCode.INVALID_REQUEST.message());
        return invalidRequest(message);
    }

    @ExceptionHandler(HandlerMethodValidationException.class)
    public ResponseEntity<ErrorResponse> handleHandlerMethodValidation(HandlerMethodValidationException exception) {
        String message = exception.getAllErrors().stream()
            .findFirst()
            .map(error -> error.getDefaultMessage())
            .orElse(ErrorCode.INVALID_REQUEST.message());
        return invalidRequest(message);
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ErrorResponse> handleConstraintViolation(ConstraintViolationException exception) {
        String message = exception.getConstraintViolations().stream()
            .findFirst()
            .map(violation -> violation.getMessage())
            .orElse(ErrorCode.INVALID_REQUEST.message());
        return invalidRequest(message);
    }

    @ExceptionHandler({MissingServletRequestParameterException.class, MethodArgumentTypeMismatchException.class})
    public ResponseEntity<ErrorResponse> handleBadRequestParameter(Exception exception) {
        log.warn("Bad request parameter: {}", exception.getMessage());
        return toResponse(ErrorResponse.of(ErrorCode.INVALID_REQUEST), ErrorCode.INVALID_REQUEST);
    }

    // 크기 제한은 프로필 사진 업로드에만 쓰이므로 해당 에러 코드로 변환한다
    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<ErrorResponse> handleMaxUploadSizeExceeded(MaxUploadSizeExceededException exception) {
        log.warn("Upload size exceeded: {}", exception.getMessage());
        return toResponse(ErrorResponse.of(ErrorCode.PROFILE_IMAGE_TOO_LARGE), ErrorCode.PROFILE_IMAGE_TOO_LARGE);
    }

    @ExceptionHandler({MissingServletRequestPartException.class, MultipartException.class})
    public ResponseEntity<ErrorResponse> handleBadMultipartRequest(Exception exception) {
        log.warn("Bad multipart request: {}", exception.getMessage());
        return toResponse(ErrorResponse.of(ErrorCode.INVALID_REQUEST), ErrorCode.INVALID_REQUEST);
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ErrorResponse> handleMessageNotReadable(HttpMessageNotReadableException exception) {
        log.warn("Malformed request body: {}", exception.getMessage());
        return toResponse(ErrorResponse.of(ErrorCode.MALFORMED_REQUEST_BODY), ErrorCode.MALFORMED_REQUEST_BODY);
    }

    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<ErrorResponse> handleNoResourceFound(NoResourceFoundException exception) {
        log.warn("Resource not found: {}", exception.getResourcePath());
        return toResponse(ErrorResponse.of(ErrorCode.RESOURCE_NOT_FOUND), ErrorCode.RESOURCE_NOT_FOUND);
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<ErrorResponse> handleMethodNotSupported(HttpRequestMethodNotSupportedException exception) {
        log.warn("Method not allowed: {}", exception.getMethod());
        return toResponse(ErrorResponse.of(ErrorCode.METHOD_NOT_ALLOWED), ErrorCode.METHOD_NOT_ALLOWED);
    }

    @ExceptionHandler(HttpMediaTypeNotSupportedException.class)
    public ResponseEntity<ErrorResponse> handleMediaTypeNotSupported(HttpMediaTypeNotSupportedException exception) {
        log.warn("Unsupported media type: {}", exception.getContentType());
        return toResponse(ErrorResponse.of(ErrorCode.UNSUPPORTED_MEDIA_TYPE), ErrorCode.UNSUPPORTED_MEDIA_TYPE);
    }

    // 인증·인가 예외는 캐치올이 500으로 삼키지 않도록 그대로 던져 보안 필터 체인의 핸들러가 401/403 ErrorResponse로 처리하게 한다
    @ExceptionHandler({AccessDeniedException.class, AuthenticationException.class})
    public void rethrowSecurityException(Exception exception) throws Exception {
        throw exception;
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleUnexpectedException(Exception exception) {
        log.error("Unexpected exception", exception);
        return toResponse(ErrorResponse.of(ErrorCode.INTERNAL_SERVER_ERROR), ErrorCode.INTERNAL_SERVER_ERROR);
    }

    private ResponseEntity<ErrorResponse> invalidRequest(String message) {
        log.warn("Invalid request: {}", message);
        return toResponse(ErrorResponse.of(ErrorCode.INVALID_REQUEST, message), ErrorCode.INVALID_REQUEST);
    }

    private ResponseEntity<ErrorResponse> toResponse(ErrorResponse body, ErrorCode errorCode) {
        return ResponseEntity.status(errorCode.httpStatus()).body(body);
    }

}
