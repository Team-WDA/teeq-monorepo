package kr.co.teeq.api.onboarding.application.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.time.LocalDate;
import java.util.UUID;
import kr.co.teeq.api.common.application.exception.ErrorResponse;
import kr.co.teeq.api.onboarding.application.dto.response.OnboardingSubmissionPageResponse;
import kr.co.teeq.api.onboarding.core.constant.OnboardingOption;
import org.springdoc.core.annotations.ParameterObject;
import org.springframework.data.domain.Pageable;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestParam;

@Tag(name = "관리자 온보딩 제출 이력", description = "관리자 전용 온보딩 제출 이력 조회(ADMIN 권한 필요)")
public interface OnboardingSubmissionAdminControllerDocs {

    @Operation(summary = "온보딩 제출 이력 조회",
        description = """
            온보딩 제출 이력을 조건에 맞게 검색해 페이지 단위로 반환한다. 모든 조건은 선택이며 비우면 제한하지 않는다.
            `from`, `to`는 KST 기준 제출일(양끝 포함)이고, 응답에는 회원 정보 없이 `memberId`만 담긴다.
            정렬은 항상 제출 시각 내림차순(최신 제출 먼저)으로 고정되며, 요청의 `sort` 값은 무시된다.
            `size`의 기본값은 20이고 상한은 100이다(초과하면 100으로 잘린다).""")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "조회 성공. 제출 시각 내림차순 페이지"),
        @ApiResponse(responseCode = "400",
            description = "`INVALID_REQUEST`: `memberId`, `from`, `to`, `optionCode`, `active`의 형식 오류(날짜는 yyyy-MM-dd, `optionCode`는 정의된 선택지 코드), `from`이 `to`보다 늦음",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "401",
            description = "`UNAUTHENTICATED`: Authorization 헤더가 없거나 Access Token이 유효하지 않음. `EXPIRED_TOKEN`: Access Token이 만료됨",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "403",
            description = "`ACCESS_DENIED`: ADMIN 권한이 없음",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<OnboardingSubmissionPageResponse> search(
        @Parameter(description = "조회할 회원 ID. 비우면 전체 회원")
        @RequestParam(value = "memberId", required = false) UUID memberId,
        @Parameter(description = "제출일 시작(KST, yyyy-MM-dd, 포함). 비우면 제한 없음", example = "2026-10-01")
        @RequestParam(value = "from", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
        @Parameter(description = "제출일 끝(KST, yyyy-MM-dd, 포함). 비우면 제한 없음", example = "2026-10-31")
        @RequestParam(value = "to", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
        @Parameter(description = "이 선택지를 포함한 제출만 조회. 비우면 제한 없음")
        @RequestParam(value = "optionCode", required = false) OnboardingOption optionCode,
        @Parameter(description = "활성 여부. true면 활성 답변이 있는 제출만, false면 모두 삭제된 제출만. 비우면 전체")
        @RequestParam(value = "active", required = false) Boolean active,
        @ParameterObject Pageable pageable);

}
