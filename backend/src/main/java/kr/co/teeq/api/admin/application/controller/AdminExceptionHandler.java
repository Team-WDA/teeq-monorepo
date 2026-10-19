package kr.co.teeq.api.admin.application.controller;

import io.swagger.v3.oas.annotations.Hidden;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.ConstraintViolationException;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpStatus;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.validation.BindException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.method.annotation.HandlerMethodValidationException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.ModelAndView;

/**
 * 관리자 화면 컨트롤러의 오류를 JSON 대신 화면으로 보여 준다. 범위 제한 없는 {@code GlobalExceptionHandler}보다 먼저 적용되도록
 * 가장 높은 우선순위를 준다. {@code @WebMvcTest}가 모든 advice를 올리므로 주입 의존성을 두지 않는다.
 */
@Slf4j
@Hidden
@ControllerAdvice(basePackageClasses = AdminLoginController.class)
@Order(Ordered.HIGHEST_PRECEDENCE)
public class AdminExceptionHandler {

    private static final String ERROR_VIEW = "admin/error";
    private static final String ERROR_MESSAGE_FRAGMENT = "admin/fragments/error-message :: error-message";
    private static final String HTMX_HEADER = "HX-Request";
    // 공통 셸의 htmx 오류 알림 영역. 셸의 id와 같아야 한다
    private static final String HTMX_ERROR_NOTICE_SELECTOR = "#htmx-error-notice";

    @ExceptionHandler(CustomException.class)
    public ModelAndView handleCustomException(CustomException exception, HttpServletRequest request,
        HttpServletResponse response) {
        ErrorCode errorCode = exception.getErrorCode();
        if (errorCode.httpStatus() >= 500) {
            log.error("Admin page custom exception: {}", errorCode.name(), exception);
        } else {
            log.warn("Admin page custom exception: {}", errorCode.name());
        }
        return errorView(errorCode, request, response);
    }

    // 요청 값의 형식·바인딩·검증 실패는 캐치올의 500이 아니라 400 오류 화면으로 보인다
    @ExceptionHandler({
        MissingServletRequestParameterException.class,
        MethodArgumentTypeMismatchException.class,
        BindException.class,
        HandlerMethodValidationException.class,
        ConstraintViolationException.class,
        HttpMessageNotReadableException.class
    })
    public ModelAndView handleBadRequest(Exception exception, HttpServletRequest request,
        HttpServletResponse response) {
        log.warn("Admin page bad request: {}", exception.getClass().getSimpleName());
        return errorView(ErrorCode.INVALID_REQUEST, request, response);
    }

    // 보안 필터 체인이 로그인 이동·접근 거부를 처리하도록 그대로 던진다
    @ExceptionHandler({AccessDeniedException.class, AuthenticationException.class})
    public void rethrowSecurityException(Exception exception) throws Exception {
        throw exception;
    }

    // 예상하지 못한 예외는 상세(스택, SQL)를 숨기고 고정 문구만 보여 준다
    @ExceptionHandler(Exception.class)
    public ModelAndView handleUnexpectedException(Exception exception, HttpServletRequest request,
        HttpServletResponse response) {
        log.error("Admin page unexpected exception", exception);
        return errorView(ErrorCode.INTERNAL_SERVER_ERROR, request, response);
    }

    // htmx 요청이면 셸의 오류 알림 영역에 끼울 한 줄 오류 조각, 아니면 공통 셸을 쓴 오류 화면을 돌려준다
    private ModelAndView errorView(ErrorCode errorCode, HttpServletRequest request, HttpServletResponse response) {
        boolean htmxRequest = "true".equals(request.getHeader(HTMX_HEADER));
        if (htmxRequest) {
            response.setHeader("HX-Retarget", HTMX_ERROR_NOTICE_SELECTOR);
            response.setHeader("HX-Reswap", "innerHTML");
        }
        ModelAndView modelAndView = new ModelAndView(htmxRequest ? ERROR_MESSAGE_FRAGMENT : ERROR_VIEW);
        modelAndView.setStatus(HttpStatus.valueOf(errorCode.httpStatus()));
        modelAndView.addObject("errorMessage", errorCode.message());
        return modelAndView;
    }

}
