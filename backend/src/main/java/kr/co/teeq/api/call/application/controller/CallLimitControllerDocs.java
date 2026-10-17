package kr.co.teeq.api.call.application.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import kr.co.teeq.api.call.application.dto.response.CallLimitStatusResponse;
import kr.co.teeq.api.common.application.exception.ErrorResponse;
import kr.co.teeq.api.member.core.principal.AuthenticatedMember;
import org.springframework.http.ResponseEntity;

@Tag(name = "통화 한도", description = "오늘 통화 한도 조회")
public interface CallLimitControllerDocs {

    @Operation(summary = "오늘 통화 한도 조회",
        description = """
            오늘(KST 0시 기준) 사용한 통화 시간과 남은 시간, 이번 통화의 허용 시간, 통화 시작 가능 여부를 반환한다.
            남은 시간이 부족해도 오류가 아니라 `canStart=false`로 응답한다.""")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "조회 성공"),
        @ApiResponse(responseCode = "401",
            description = "`UNAUTHENTICATED`: Authorization 헤더가 없거나 Access Token이 유효하지 않거나 삭제된 회원임. `EXPIRED_TOKEN`: Access Token이 만료됨(토큰 재발급 후 재시도)",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<CallLimitStatusResponse> getTodayStatus(
        @Parameter(hidden = true) AuthenticatedMember authenticatedMember);

}
