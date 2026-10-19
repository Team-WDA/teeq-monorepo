package kr.co.teeq.api.member.application.controller;

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
import kr.co.teeq.api.common.application.exception.ErrorResponse;
import kr.co.teeq.api.member.application.dto.request.ChangeNicknameRequest;
import kr.co.teeq.api.member.application.dto.request.SignupCompletionRequest;
import kr.co.teeq.api.member.application.dto.response.MemberResponse;
import kr.co.teeq.api.member.application.dto.response.NicknameAvailabilityResponse;
import kr.co.teeq.api.member.core.constant.MemberValidation;
import kr.co.teeq.api.member.core.principal.AuthenticatedMember;
import org.springframework.http.ResponseEntity;
import org.springframework.web.multipart.MultipartFile;

@Tag(name = "회원", description = "내 정보 조회, 가입 완료, 닉네임 변경, 닉네임 중복 확인, 프로필 사진 교체·삭제")
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

    @Operation(summary = "가입 완료",
        description = """
            소셜 첫 로그인으로 만들어진 가입 미완료 회원(`nickname`이 NULL)이 닉네임과 필수 약관 동의를 제출해 가입을 마친다.
            가입을 마치기 전에는 내 정보 조회, 가입 완료, 로그아웃, 탈퇴와 공개 경로 외의 API가 403 `SIGNUP_NOT_COMPLETED`로 막힌다.
            이 API는 가입 미완료 회원도 호출할 수 있으므로 `SIGNUP_NOT_COMPLETED`로 응답하지 않는다.""")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "가입 완료 성공. 닉네임이 채워진 회원 정보 반환"),
        @ApiResponse(responseCode = "400",
            description = "`INVALID_REQUEST`: 닉네임이 비었거나 규칙 위반, 또는 필수 약관에 동의하지 않음(`errorMessage`에 사유). `MALFORMED_REQUEST_BODY`: 요청 본문이 올바른 JSON이 아님",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "401",
            description = "`UNAUTHENTICATED`: Authorization 헤더가 없거나 Access Token이 유효하지 않음. `EXPIRED_TOKEN`: Access Token이 만료됨",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "404",
            description = "`MEMBER_NOT_FOUND`: 인증 직후 회원이 삭제된 경우(드묾)",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "409",
            description = "`STATE_CONFLICT`: 이미 가입을 완료한 회원. `DUPLICATE_NICKNAME`: 다른 회원이 이미 사용 중인 닉네임",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<MemberResponse> completeSignup(
        @Parameter(hidden = true) AuthenticatedMember authenticatedMember,
        @Valid SignupCompletionRequest request);

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

    @Operation(summary = "프로필 사진 교체",
        description = """
            프로필 사진을 올린다. 이미 사진이 있으면 새 사진으로 교체한다.
            요청은 `multipart/form-data`이고 파일 파트 이름은 `image`다. JPEG, PNG, WebP만 허용하며 최대 5MB다.
            형식은 파일 내용으로 판별하므로 확장자와 content type이 달라도 내용이 허용 형식이면 통과한다.
            응답의 `profileImageUrl`은 절대 URL이므로 앱이 그대로 요청한다.""")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "교체 성공. 갱신된 회원 정보 반환"),
        @ApiResponse(responseCode = "400",
            description = "`PROFILE_IMAGE_INVALID`: 빈 파일이거나 JPEG, PNG, WebP가 아님. `INVALID_REQUEST`: multipart 본문을 해석할 수 없거나 `image` 파트가 없음",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "401",
            description = "`UNAUTHENTICATED`: Authorization 헤더가 없거나 Access Token이 유효하지 않음. `EXPIRED_TOKEN`: Access Token이 만료됨",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "409",
            description = "`STATE_CONFLICT`: 같은 회원의 사진 교체 요청이 동시에 들어와 충돌함(다시 시도)",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "413",
            description = "`PROFILE_IMAGE_TOO_LARGE`: 파일이 5MB를 넘음",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "415",
            description = "`UNSUPPORTED_MEDIA_TYPE`: 요청이 `multipart/form-data`가 아님",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "500",
            description = "`INTERNAL_SERVER_ERROR`: 사진 파일을 저장하지 못함",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<MemberResponse> replaceProfileImage(
        @Parameter(hidden = true) AuthenticatedMember authenticatedMember,
        @Parameter(description = "프로필 사진 파일. JPEG, PNG, WebP, 최대 5MB") MultipartFile image);

    @Operation(summary = "프로필 사진 삭제",
        description = "프로필 사진을 삭제한다. 사진이 없어도 204로 응답한다(멱등).")
    @ApiResponses({
        @ApiResponse(responseCode = "204", description = "삭제 성공(사진이 없던 경우 포함)"),
        @ApiResponse(responseCode = "401",
            description = "`UNAUTHENTICATED`: Authorization 헤더가 없거나 Access Token이 유효하지 않음. `EXPIRED_TOKEN`: Access Token이 만료됨",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<Void> deleteProfileImage(@Parameter(hidden = true) AuthenticatedMember authenticatedMember);

}
