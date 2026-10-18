package kr.co.teeq.api.call.application.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import kr.co.teeq.api.call.application.dto.response.CallStartResponse;
import kr.co.teeq.api.common.application.exception.ErrorResponse;
import kr.co.teeq.api.member.core.principal.AuthenticatedMember;
import org.springframework.http.ResponseEntity;

@Tag(name = "통화", description = "통화 시작")
public interface CallControllerDocs {

    @Operation(summary = "통화 시작",
        description = """
            오늘 남은 통화 시간을 확인하고 AI 서버에 통화 세션 생성을 요청한다.
            응답의 `maxDurationSeconds`가 이번 통화의 허용 시간(초)이며, `connection`은 앱이 통화 접속에 쓰는 AI 서버 응답 필드이다.
            1회 통화 한도를 넘겨 종료 보고가 없는 이전 통화는 만료 처리되어 새 통화를 시작할 수 있다.""")
    @ApiResponses({
        @ApiResponse(responseCode = "201", description = "통화 세션 생성 성공"),
        @ApiResponse(responseCode = "401",
            description = "`UNAUTHENTICATED`: Authorization 헤더가 없거나 Access Token이 유효하지 않거나 삭제된 회원임. `EXPIRED_TOKEN`: Access Token이 만료됨(토큰 재발급 후 재시도)",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "403",
            description = "`CALL_LIMIT_INSUFFICIENT`: 오늘 남은 통화 시간(관리자가 부여한 추가 시간 포함)이 시작 최소 시간보다 적음. `CALL_SERVICE_LIMIT_EXCEEDED`: 서비스 전체의 이번 달 통화 한도가 소진되어 지금은 통화를 시작할 수 없음",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "409",
            description = "`CALL_ALREADY_IN_PROGRESS`: 이미 진행 중인 통화가 있음(동시에 두 번 요청한 경우 포함)",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "502",
            description = "`AI_SERVER_UNAVAILABLE`: AI 서버가 응답하지 않거나 오류를 반환했거나 통화 세션 ID가 없음. 이 경우 통화 기록은 실패 처리되어 한도에 포함되지 않음",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<CallStartResponse> start(@Parameter(hidden = true) AuthenticatedMember authenticatedMember);

}
