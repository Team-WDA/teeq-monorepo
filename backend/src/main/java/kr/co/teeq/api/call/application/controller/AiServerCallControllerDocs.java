package kr.co.teeq.api.call.application.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import kr.co.teeq.api.call.application.dto.request.CallUsageReportRequest;
import kr.co.teeq.api.call.application.dto.response.CallHistoryResponse;
import kr.co.teeq.api.common.application.exception.ErrorResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;

@Tag(name = "통화(AI 서버)", description = "AI 서버가 호출하는 통화 종료 보고. 공유 헤더 인증이 필요하다")
public interface AiServerCallControllerDocs {

    @Operation(summary = "통화 종료 보고",
        description = """
            AI 서버가 통화 종료 시 실제 사용 시간(초), 종료 시각, 종료 이유(`endReason`)를 보고한다. 회원 JWT가 아니라 AI 서버 공유 헤더(`X-Teeq-Server-Key`)로 인증한다.
            `endReason`은 `USER_HANGUP`, `USER_DISCONNECTED`, `LIMIT_REACHED`, `AGENT_ERROR`, `DISPATCH_FAILED` 중 하나이며 필수다. `DISPATCH_FAILED`는 AI 서버가 보고하지 않는다.
            같은 세션을 다시 보고하면 종료 이유를 포함해 첫 값을 유지하고 현재 기록을 그대로 돌려준다(멱등).
            1회 통화 한도를 넘겨 만료 처리된 기록도 늦게 온 보고로 종료 상태로 덮어쓴다.
            사용 시간이 1회 통화 한도를 넘으면 1회 한도로 잘라 저장한다.""")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "종료 보고 반영 성공(중복 보고 포함)"),
        @ApiResponse(responseCode = "400",
            description = "`INVALID_REQUEST`: 사용 시간이 없거나 음수이거나 종료 시각 또는 종료 이유가 없음(`errorMessage`에 사유). `MALFORMED_REQUEST_BODY`: 요청 본문이 올바른 JSON이 아니거나 알 수 없는 `endReason` 값",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "401",
            description = "`UNAUTHENTICATED`: AI 서버 공유 헤더가 없거나 값이 일치하지 않음",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "404",
            description = "`CALL_SESSION_NOT_FOUND`: 해당 통화 세션 ID의 기록이 없음",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<CallHistoryResponse> reportUsage(
        @PathVariable("call-session-id") String callSessionId,
        @Valid @RequestBody CallUsageReportRequest request);

}
