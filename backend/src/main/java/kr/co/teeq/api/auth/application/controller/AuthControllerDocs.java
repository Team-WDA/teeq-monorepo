package kr.co.teeq.api.auth.application.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirements;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import kr.co.teeq.api.auth.application.dto.request.RefreshRequest;
import kr.co.teeq.api.auth.application.dto.request.LoginRequest;
import kr.co.teeq.api.auth.application.dto.request.SignUpRequest;
import kr.co.teeq.api.auth.application.dto.response.AuthResponse;
import kr.co.teeq.api.common.application.exception.ErrorResponse;
import kr.co.teeq.api.member.core.principal.AuthenticatedMember;
import org.springframework.http.ResponseEntity;

@Tag(name = "인증", description = "로그인, 가입, 토큰 재발급, 로그아웃")
public interface AuthControllerDocs {

    @Operation(summary = "로그인",
        description = """
            Firebase ID token(Apple, Google 또는 이메일/비밀번호 로그인으로 얻음)을 서버에서 검증해 로그인하고
            Access Token(1일)과 Refresh Token(30일)을 발급한다. 새 로그인은 기존 Refresh Token을 대체한다(다기기 로그인 없음).
            회원 식별 키는 Firebase uid이고, 로그인 방식은 토큰의 `firebase.sign_in_provider`(`apple.com`→APPLE, `google.com`→GOOGLE, `password`→EMAIL)로 정한다.
            비밀번호는 서버가 받지도 저장하지도 않는다. 같은 uid인데 저장된 로그인 방식과 토큰의 제공자가 다르면 401 `AUTH_TOKEN_INVALID`다.
            이 API는 회원을 만들지 않는다. 처음 보는 계정이면 404 `AUTH_SIGNUP_REQUIRED`로 응답하며,
            앱은 약관 동의와 닉네임 입력을 받은 뒤 `POST /api/auth/signup`으로 가입한다.
            탈퇴한 계정도 처음 보는 계정과 같이 404 `AUTH_SIGNUP_REQUIRED`로 응답하며 다시 가입할 수 있다.""")
    @SecurityRequirements
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "로그인 성공"),
        @ApiResponse(responseCode = "400",
            description = "`INVALID_REQUEST`: 인증 정보가 비어 있거나 4096자 초과(`errorMessage`에 사유). `MALFORMED_REQUEST_BODY`: 요청 본문이 올바른 JSON이 아님",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "401",
            description = "`AUTH_TOKEN_INVALID`: 토큰이 위조·만료되었거나 지원하지 않는 로그인 제공자이거나 토큰에 이메일이 없거나 폐기된 토큰이거나 저장된 로그인 방식과 제공자가 다름",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "404",
            description = "`AUTH_SIGNUP_REQUIRED`: 가입되지 않은 계정. 약관 동의와 닉네임을 받아 `signup`을 호출한다",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "502",
            description = "`AUTH_SERVER_UNAVAILABLE`: Firebase 공개키를 조회할 수 없음. 잠시 후 다시 시도한다",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<AuthResponse> login(@Valid LoginRequest request);

    @Operation(summary = "가입",
        description = """
            Firebase ID token을 검증하고, 닉네임과 필수 약관 동의를 받아 회원을 만든 뒤
            Access Token(1일)과 Refresh Token(30일)을 발급한다. `login`이 404 `AUTH_SIGNUP_REQUIRED`로 응답한 뒤에 호출한다.
            토큰은 `login`과 같은 규칙으로 검증한다(폐기 여부 포함).""")
    @SecurityRequirements
    @ApiResponses({
        @ApiResponse(responseCode = "201", description = "가입 후 로그인 성공"),
        @ApiResponse(responseCode = "400",
            description = "`INVALID_REQUEST`: 인증 정보가 비었거나 4096자 초과, 닉네임이 비었거나 규칙 위반, 필수 약관에 동의하지 않음(`errorMessage`에 사유). `MALFORMED_REQUEST_BODY`: 요청 본문이 올바른 JSON이 아님",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "401",
            description = "`AUTH_TOKEN_INVALID`: 토큰이 위조·만료되었거나 지원하지 않는 로그인 제공자이거나 토큰에 이메일이 없거나 폐기된 토큰이거나 저장된 로그인 방식과 제공자가 다름",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "409",
            description = "`STATE_CONFLICT`: 이미 가입된 계정(앱은 `login`으로 로그인한다). `DUPLICATE_NICKNAME`: 다른 회원이 이미 사용 중인 닉네임",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "502",
            description = "`AUTH_SERVER_UNAVAILABLE`: Firebase 공개키를 조회할 수 없음. 잠시 후 다시 시도한다",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<AuthResponse> signUp(@Valid SignUpRequest request);

    @Operation(summary = "토큰 재발급",
        description = """
            Refresh Token으로 새 Access Token과 Refresh Token을 발급한다(Refresh Token 로테이션).
            응답으로 받은 새 Refresh Token으로 교체해야 하며, 교체되기 전의 이전 Refresh Token은 다시 쓸 수 없다.""")
    @SecurityRequirements
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "재발급 성공"),
        @ApiResponse(responseCode = "400",
            description = "`INVALID_REQUEST`: 리프레시 토큰이 비어 있음. `MALFORMED_REQUEST_BODY`: 요청 본문이 올바른 JSON이 아님",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "401",
            description = "`INVALID_REFRESH_TOKEN`: 토큰이 위조·만료되었거나 Access Token을 보냈거나 이미 교체·폐기(로그아웃, 계정 삭제)된 토큰이거나 삭제된 회원의 토큰임. 다시 로그인해야 한다",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<AuthResponse> refresh(@Valid RefreshRequest request);

    @Operation(summary = "로그아웃",
        description = """
            현재 회원의 Refresh Token을 삭제한다. 이미 발급된 Access Token은 만료될 때까지 유효하므로 클라이언트가 직접 폐기해야 한다.""")
    @ApiResponses({
        @ApiResponse(responseCode = "204", description = "로그아웃 성공(본문 없음)"),
        @ApiResponse(responseCode = "401",
            description = "`UNAUTHENTICATED`: Authorization 헤더가 없거나 Access Token이 유효하지 않거나 삭제된 회원임. `EXPIRED_TOKEN`: Access Token이 만료됨(토큰 재발급 후 재시도)",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<Void> logout(@Parameter(hidden = true) AuthenticatedMember authenticatedMember);

}
