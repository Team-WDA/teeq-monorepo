package kr.teeq.api.member.application.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirements;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Pattern;
import kr.teeq.api.common.application.exception.ErrorResponse;
import kr.teeq.api.member.application.dto.request.ChangeNicknameRequest;
import kr.teeq.api.member.application.dto.response.MemberResponse;
import kr.teeq.api.member.application.dto.response.NicknameAvailabilityResponse;
import kr.teeq.api.member.core.constant.MemberValidation;
import kr.teeq.api.member.core.principal.AuthenticatedMember;
import org.springframework.http.ResponseEntity;

@Tag(name = "회원", description = "내 정보 조회, 닉네임 변경, 닉네임 중복 확인")
public interface MemberControllerDocs {

    @Operation(summary = "닉네임 사용 가능 여부 확인",
        description = """
            닉네임이 규칙(한글·영문·숫자 2~10자)에 맞고 활성 회원 중 아무도 쓰지 않는지 확인한다. 대소문자는 구분하지 않는다.
            규칙에 어긋나면 `available=false`가 아니라 400 `INVALID_REQUEST`로 응답한다.
            확인과 가입 사이에 다른 사람이 선점할 수 있으므로 가입·변경 시 409 `DUPLICATE_NICKNAME`도 처리해야 한다.""")
    @SecurityRequirements
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "확인 성공. `available`로 사용 가능 여부를 반환"),
        @ApiResponse(responseCode = "400",
            description = "`INVALID_REQUEST`: nickname 파라미터가 없거나 닉네임 규칙 위반(`errorMessage`에 사유)",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<NicknameAvailabilityResponse> checkNicknameAvailability(
        @Parameter(description = "확인할 닉네임. 한글, 영문, 숫자만 사용해 2~10자", example = "티큐")
        @Pattern(regexp = MemberValidation.NICKNAME_REGEX, message = MemberValidation.NICKNAME_MESSAGE)
        String nickname);

    @Operation(summary = "내 정보 조회", description = "Access Token의 회원 정보를 반환한다.")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "조회 성공"),
        @ApiResponse(responseCode = "401",
            description = "`UNAUTHENTICATED`: Authorization 헤더가 없거나 Access Token이 유효하지 않거나 삭제된 회원임. `EXPIRED_TOKEN`: Access Token이 만료됨(토큰 재발급 후 재시도)",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<MemberResponse> getMe(@Parameter(hidden = true) AuthenticatedMember authenticatedMember);

    @Operation(summary = "닉네임 변경",
        description = """
            닉네임을 변경한다. 변경 횟수 제한은 없다. 자신의 닉네임을 대소문자만 바꾸는 것은 허용한다.""")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "변경 성공. 변경된 회원 정보 반환"),
        @ApiResponse(responseCode = "400",
            description = "`INVALID_REQUEST`: 닉네임이 비었거나 규칙 위반(`errorMessage`에 사유). `MALFORMED_REQUEST_BODY`: 요청 본문이 올바른 JSON이 아님",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "401",
            description = "`UNAUTHENTICATED`: Authorization 헤더가 없거나 Access Token이 유효하지 않음. `EXPIRED_TOKEN`: Access Token이 만료됨",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "404",
            description = "`MEMBER_NOT_FOUND`: 인증 직후 회원이 삭제된 경우(드묾)",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "409",
            description = "`DUPLICATE_NICKNAME`: 다른 회원이 이미 사용 중인 닉네임",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<MemberResponse> changeNickname(
        @Parameter(hidden = true) AuthenticatedMember authenticatedMember,
        @Valid ChangeNicknameRequest request);

}
