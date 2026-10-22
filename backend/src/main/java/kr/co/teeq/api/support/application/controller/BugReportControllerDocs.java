package kr.co.teeq.api.support.application.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import kr.co.teeq.api.common.application.exception.ErrorResponse;
import kr.co.teeq.api.member.core.principal.AuthenticatedMember;
import kr.co.teeq.api.support.application.dto.request.BugReportCreateRequest;
import kr.co.teeq.api.support.application.dto.response.BugReportCreateResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.multipart.MultipartFile;

@Tag(name = "버그 제보", description = "앱에서 버그를 제보한다")
public interface BugReportControllerDocs {

    @Operation(summary = "버그 제보 등록",
        description = """
            `multipart/form-data`로 보낸다. `request` 파트는 반드시 `Content-Type: application/json`이어야 하고(없으면 415),
            파일명이 있는 JSON 파일 파트로 보내야 한다(파일명이 없으면 폼 파라미터로 파싱되어 2MB 제한을 받는다).
            `images` 파트는 0~5개를 같은 이름으로 반복해 보낸다(JPEG·PNG·WebP, 장당 5MB 이하).
            `source`가 `USER`이면 로그를 보내지 않는다. `DEVELOPER_CONSOLE`이면 `errorLogs`, `networkLogs`를 각각 100개 이하,
            전체 직렬화 크기 합계 5MB 이하로 보낼 수 있고, 잘려 나간 개수는 `omittedErrorLogCount`, `omittedNetworkLogCount`에 담는다.
            저장되면 개발자에게 알림이 가지만 알림 실패는 응답에 영향을 주지 않는다.""")
    @ApiResponses({
        @ApiResponse(responseCode = "201", description = "등록 성공. 제보 id를 반환"),
        @ApiResponse(responseCode = "400",
            description = "`INVALID_REQUEST`: `request` 파트가 없거나 필드 검증 실패(내용 비어 있음·2000자 초과, 환경 정보 누락 등, `errorMessage`에 사유), "
                + "`source`가 `USER`인데 로그가 있음, 로그가 100개를 넘거나 합계 5MB를 넘음. "
                + "`MALFORMED_REQUEST_BODY`: `request` 파트가 올바른 JSON이 아니거나 없는 enum 값임. "
                + "`BUG_REPORT_IMAGE_TOO_MANY`: 이미지가 5장을 넘음(업로드 0건). "
                + "`BUG_REPORT_IMAGE_INVALID`: 이미지가 비어 있거나 JPEG·PNG·WebP가 아님(업로드 0건)",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "401",
            description = "`UNAUTHENTICATED`: Authorization 헤더가 없거나 Access Token이 유효하지 않거나 삭제된 회원임. `EXPIRED_TOKEN`: Access Token이 만료됨(토큰 재발급 후 재시도)",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "403",
            description = "`SIGNUP_NOT_COMPLETED`: 약관 동의 등 가입을 완료하지 않은 회원임",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "413",
            description = "`BUG_REPORT_IMAGE_TOO_LARGE`: 이미지 한 장이 5MB를 넘음(업로드 0건)",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "415",
            description = "`UNSUPPORTED_MEDIA_TYPE`: `request` 파트에 `application/json` content type이 없음",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<BugReportCreateResponse> create(
        @Parameter(hidden = true) AuthenticatedMember authenticatedMember,
        @Valid BugReportCreateRequest request,
        List<MultipartFile> images);

}
