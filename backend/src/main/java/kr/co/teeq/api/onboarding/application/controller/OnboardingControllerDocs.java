package kr.co.teeq.api.onboarding.application.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import kr.co.teeq.api.common.application.exception.ErrorResponse;
import kr.co.teeq.api.member.core.principal.AuthenticatedMember;
import kr.co.teeq.api.onboarding.application.dto.response.OnboardingAnswersResponse;
import org.springframework.http.ResponseEntity;

@Tag(name = "온보딩", description = "온보딩 답변 조회")
public interface OnboardingControllerDocs {

    @Operation(summary = "온보딩 답변 조회",
        description = """
            로그인한 회원이 저장한 온보딩 답변을 질문별로 묶어 질문 순서대로 반환한다.
            저장된 답변이 없으면 오류가 아니라 `answers`가 빈 배열인 200으로 응답한다.""")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "조회 성공"),
        @ApiResponse(responseCode = "401",
            description = "`UNAUTHENTICATED`: Authorization 헤더가 없거나 Access Token이 유효하지 않거나 삭제된 회원임. `EXPIRED_TOKEN`: Access Token이 만료됨(토큰 재발급 후 재시도)",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<OnboardingAnswersResponse> getAnswers(
        @Parameter(hidden = true) AuthenticatedMember authenticatedMember);

}
