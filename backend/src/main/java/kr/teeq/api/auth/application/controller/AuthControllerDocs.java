package kr.teeq.api.auth.application.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirements;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import kr.teeq.api.auth.application.dto.request.LoginRequest;
import kr.teeq.api.auth.application.dto.request.RefreshRequest;
import kr.teeq.api.auth.application.dto.request.SocialLoginRequest;
import kr.teeq.api.auth.application.dto.response.AuthResponse;
import kr.teeq.api.common.application.exception.ErrorResponse;
import kr.teeq.api.member.core.principal.AuthenticatedMember;
import org.springframework.http.ResponseEntity;

@Tag(name = "인증", description = "이메일 로그인, 소셜 로그인, 토큰 재발급, 로그아웃")
public interface AuthControllerDocs {

    @Operation(summary = "로그인",
        description = """
            이메일과 비밀번호로 로그인하고 Access Token(1일)과 Refresh Token(30일)을 발급한다.
            이메일은 앞뒤 공백을 제거하고 소문자로 바꿔 비교한다. 새 로그인은 기존 Refresh Token을 대체한다(다기기 로그인 없음).
            이메일이 없거나 비밀번호가 다르면 구분하지 않고 `INVALID_CREDENTIALS` 하나로 응답한다.
            다만 해당 이메일이 소셜 로그인으로 가입한 계정이면 `LOGIN_METHOD_MISMATCH`로 응답한다
            (앱이 올바른 로그인 방식으로 안내하기 위한 의도적 결정이며, 이메일의 가입 여부가 드러날 수 있다).""")
    @SecurityRequirements
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "로그인 성공"),
        @ApiResponse(responseCode = "400",
            description = "`INVALID_REQUEST`: 이메일 또는 비밀번호가 비어 있음. `MALFORMED_REQUEST_BODY`: 요청 본문이 올바른 JSON이 아님",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "401",
            description = "`INVALID_CREDENTIALS`: 이메일 또는 비밀번호가 올바르지 않음. `LOGIN_METHOD_MISMATCH`: 소셜 로그인으로 가입한 계정이라 비밀번호로 로그인할 수 없음",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<AuthResponse> login(@Valid LoginRequest request);

    @Operation(summary = "소셜 로그인",
        description = """
            소셜 제공자(현재 Apple)가 발급한 토큰을 서버에서 검증해 로그인하고, 처음 로그인하면 가입까지 처리한 뒤
            Access Token(1일)과 Refresh Token(30일)을 발급한다. 새 로그인은 기존 Refresh Token을 대체한다(다기기 로그인 없음).
            이미 가입한 소셜 계정이면 로그인(200)하며 `nickname`과 약관 동의 값은 무시한다.
            처음 로그인하는 계정은 `nickname`과 두 약관 동의가 모두 있어야 가입(201)된다. 하나라도 없으면 `SOCIAL_SIGNUP_REQUIRED`(409)로
            응답하므로 앱은 닉네임·약관 입력 화면을 거쳐 같은 `credential`로 다시 요청한다(토큰이 만료되었으면 제공자 로그인을 다시 한다).
            약관 동의 값을 보낸다면 true여야 하며, 이미 가입한 회원의 로그인 요청이라도 false를 보내면 400이다.
            제공자가 준 이메일과 같은 이메일의 활성 계정이 이미 있으면 자동으로 연동하지 않고 `DUPLICATE_EMAIL`로 응답한다.
            탈퇴한 소셜 계정으로 다시 로그인하면 신규 가입으로 처리한다.""")
    @SecurityRequirements
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "기존 소셜 계정으로 로그인 성공"),
        @ApiResponse(responseCode = "201", description = "신규 가입 후 로그인 성공"),
        @ApiResponse(responseCode = "400",
            description = "`INVALID_REQUEST`: 제공자·인증 정보가 비어 있거나 4096자 초과, 닉네임 규칙 위반, 약관 동의 값이 false 등 입력 검증 실패(`errorMessage`에 사유). `MALFORMED_REQUEST_BODY`: 요청 본문이 올바른 JSON이 아니거나 알 수 없는 제공자",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "401",
            description = "`SOCIAL_TOKEN_INVALID`: 토큰이 위조·만료되었거나 대상 앱이 다르거나 이메일을 확인할 수 없음",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "409",
            description = "`SOCIAL_SIGNUP_REQUIRED`: 신규 가입에 필요한 닉네임 또는 약관 동의가 없음. `DUPLICATE_EMAIL`: 같은 이메일의 계정이 이미 있음. `DUPLICATE_NICKNAME`: 이미 사용 중인 닉네임(대소문자 구분 없음)",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "502",
            description = "`SOCIAL_SERVER_UNAVAILABLE`: 소셜 제공자의 공개키를 조회할 수 없음. 잠시 후 다시 시도한다",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<AuthResponse> socialLogin(@Valid SocialLoginRequest request);

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
