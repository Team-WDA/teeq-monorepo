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
import kr.teeq.api.auth.application.dto.request.ChangePasswordRequest;
import kr.teeq.api.auth.application.dto.request.SignUpRequest;
import kr.teeq.api.auth.application.dto.response.AuthResponse;
import kr.teeq.api.common.application.exception.ErrorResponse;
import kr.teeq.api.member.core.principal.AuthenticatedMember;
import org.springframework.http.ResponseEntity;

@Tag(name = "계정", description = "회원 가입, 비밀번호 변경, 계정 삭제")
public interface AccountControllerDocs {

    @Operation(summary = "회원 가입",
        description = """
            이메일, 비밀번호, 닉네임, 필수 약관 동의 2종으로 가입하고 토큰을 함께 발급한다(가입 후 별도 로그인 불필요).
            이메일은 소문자로 정규화해 저장한다. 삭제된 회원의 이메일과 닉네임은 다시 사용할 수 있다.
            닉네임 사전 확인은 `GET /api/members/nickname-availability`를 쓴다.""")
    @SecurityRequirements
    @ApiResponses({
        @ApiResponse(responseCode = "201", description = "가입 성공"),
        @ApiResponse(responseCode = "400",
            description = "`INVALID_REQUEST`: 이메일 형식 오류(앞뒤 공백 포함)·254자 초과, 비밀번호·닉네임 규칙 위반, 필수 약관 미동의 등 입력 검증 실패(`errorMessage`에 사유). `MALFORMED_REQUEST_BODY`: 요청 본문이 올바른 JSON이 아님",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "409",
            description = "`DUPLICATE_EMAIL`: 이미 사용 중인 이메일. `DUPLICATE_NICKNAME`: 이미 사용 중인 닉네임(대소문자 구분 없음)",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<AuthResponse> signUp(@Valid SignUpRequest request);

    @Operation(summary = "비밀번호 변경",
        description = """
            현재 비밀번호를 확인한 뒤 비밀번호를 변경하고 새 Access Token과 Refresh Token을 발급한다.
            이미 발급된 Access Token은 만료까지 유효하므로 응답의 새 토큰으로 교체한다.""")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "변경 성공. 새 토큰 발급"),
        @ApiResponse(responseCode = "400",
            description = "`INVALID_REQUEST`: 입력 검증 실패(새 비밀번호 규칙 위반 등). `INVALID_CURRENT_PASSWORD`: 현재 비밀번호가 올바르지 않음. `MALFORMED_REQUEST_BODY`: 요청 본문이 올바른 JSON이 아님",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "401",
            description = "`UNAUTHENTICATED`: Authorization 헤더가 없거나 Access Token이 유효하지 않음. `EXPIRED_TOKEN`: Access Token이 만료됨",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "404",
            description = "`MEMBER_NOT_FOUND`: 인증 직후 회원이 삭제된 경우(드묾)",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<AuthResponse> changePassword(
        @Parameter(hidden = true) AuthenticatedMember authenticatedMember,
        @Valid ChangePasswordRequest request);

    @Operation(summary = "계정 삭제",
        description = """
            회원을 삭제(soft delete)하고 Refresh Token을 폐기한다. 삭제된 회원의 Access Token은 즉시 `UNAUTHENTICATED`로 거부된다.""")
    @ApiResponses({
        @ApiResponse(responseCode = "204", description = "삭제 성공(본문 없음)"),
        @ApiResponse(responseCode = "401",
            description = "`UNAUTHENTICATED`: Authorization 헤더가 없거나 Access Token이 유효하지 않음. `EXPIRED_TOKEN`: Access Token이 만료됨",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "404",
            description = "`MEMBER_NOT_FOUND`: 인증 직후 회원이 이미 삭제된 경우(드묾)",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<Void> deleteAccount(@Parameter(hidden = true) AuthenticatedMember authenticatedMember);

}
