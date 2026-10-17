package kr.co.teeq.api.common.application.exception;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import org.junit.jupiter.api.Test;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.multipart.MultipartException;
import org.springframework.web.multipart.support.MissingServletRequestPartException;

class GlobalExceptionHandlerTest {

    private final GlobalExceptionHandler handler = new GlobalExceptionHandler();

    @Test
    void handleCustomException_mapsErrorCodeToStatusAndBody() {
        CustomException exception = new CustomException(ErrorCode.STATE_CONFLICT);

        ResponseEntity<ErrorResponse> response = handler.handleCustomException(exception);

        assertThat(response.getStatusCode().value()).isEqualTo(409);
        assertThat(response.getBody()).isEqualTo(
            new ErrorResponse("STATE_CONFLICT", ErrorCode.STATE_CONFLICT.message()));
    }

    @Test
    void handleUnexpectedException_hidesInternalMessage() {
        Exception exception = new IllegalStateException("jdbc:postgresql://internal-host/secret-db");

        ResponseEntity<ErrorResponse> response = handler.handleUnexpectedException(exception);

        assertThat(response.getStatusCode().value()).isEqualTo(500);
        assertThat(response.getBody().errorCode()).isEqualTo("INTERNAL_SERVER_ERROR");
        assertThat(response.getBody().errorMessage()).isEqualTo(ErrorCode.INTERNAL_SERVER_ERROR.message());
        assertThat(response.getBody().errorMessage()).doesNotContain("internal-host");
    }

    @Test
    void handleMaxUploadSizeExceeded_mapsToProfileImageTooLarge() {
        ResponseEntity<ErrorResponse> response =
            handler.handleMaxUploadSizeExceeded(new MaxUploadSizeExceededException(200L * 1024 * 1024));

        assertThat(response.getStatusCode().value()).isEqualTo(413);
        assertThat(response.getBody().errorCode()).isEqualTo("PROFILE_IMAGE_TOO_LARGE");
    }

    @Test
    void handleBadMultipartRequest_mapsMissingPartAndNonMultipartToInvalidRequest() {
        ResponseEntity<ErrorResponse> missingPart =
            handler.handleBadMultipartRequest(new MissingServletRequestPartException("image"));
        ResponseEntity<ErrorResponse> notMultipart =
            handler.handleBadMultipartRequest(new MultipartException("not multipart"));

        assertThat(missingPart.getStatusCode().value()).isEqualTo(400);
        assertThat(missingPart.getBody().errorCode()).isEqualTo("INVALID_REQUEST");
        assertThat(notMultipart.getStatusCode().value()).isEqualTo(400);
        assertThat(notMultipart.getBody().errorCode()).isEqualTo("INVALID_REQUEST");
    }

    @Test
    void rethrowSecurityException_propagatesAccessDeniedAndAuthenticationExceptions() {
        assertThatThrownBy(() -> handler.rethrowSecurityException(new AccessDeniedException("denied")))
            .isInstanceOf(AccessDeniedException.class);
        assertThatThrownBy(() -> handler.rethrowSecurityException(new BadCredentialsException("bad")))
            .isInstanceOf(BadCredentialsException.class);
    }

}
