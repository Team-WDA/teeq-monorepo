package kr.teeq.api.call.application.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import kr.teeq.api.call.application.dto.request.CallHistoryRecordRequest;
import kr.teeq.api.call.application.dto.request.CallLimitCheckRequest;
import kr.teeq.api.call.application.dto.response.CallHistoryResponse;
import kr.teeq.api.call.application.dto.response.CallLimitCheckResponse;
import kr.teeq.api.common.application.exception.ErrorResponse;
import org.springframework.http.ResponseEntity;

@Tag(name = "통화 내부 API", description = "AI 서버 호출용. 서버 간 인증은 #7에서 적용 예정(현재는 일반 인증만)")
public interface CallInternalControllerDocs {

    @Operation(summary = "통화 시작 가능 여부 검사",
        description = """
            AI 서버가 통화를 시작하기 전에 호출한다. 오늘(KST 0시 기준) 남은 시간이 최소 시작 시간 이상이면 이번 통화의 허용 시간(초)을 반환한다.
            남은 시간이 부족하면 403 `CALL_LIMIT_INSUFFICIENT`로 응답한다.""")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "통화 시작 가능. `allowedSeconds`로 이번 통화의 허용 시간(초)을 반환"),
        @ApiResponse(responseCode = "400",
            description = "`INVALID_REQUEST`: memberId가 비어 있음. `MALFORMED_REQUEST_BODY`: 요청 본문이 올바른 JSON이 아니거나 memberId 형식이 UUID가 아님",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "401",
            description = "`UNAUTHENTICATED`: Authorization 헤더가 없거나 Access Token이 유효하지 않음. `EXPIRED_TOKEN`: Access Token이 만료됨",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "403",
            description = "`CALL_LIMIT_INSUFFICIENT`: 오늘 남은 통화 시간이 최소 시작 시간보다 적음",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "404",
            description = "`MEMBER_NOT_FOUND`: 존재하지 않거나 삭제된 회원",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<CallLimitCheckResponse> checkCallLimit(@Valid CallLimitCheckRequest request);

    @Operation(summary = "통화 사용 시간 기록",
        description = """
            AI 서버가 통화 종료 후 통화 시간을 보고한다. 보고된 시간이 1회 한도를 넘으면 1회 한도로 잘라 저장한다.
            같은 `callSessionId`를 다시 보내면 오류 없이 이미 저장된 기록을 그대로 반환한다(새 값으로 덮어쓰지 않는다).
            새로 기록하면 201, 이미 기록된 세션이면 200으로 응답한다.""")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "이미 기록된 통화 세션. 저장되어 있던 기록을 그대로 반환"),
        @ApiResponse(responseCode = "201", description = "기록 성공. 저장된 기록을 반환"),
        @ApiResponse(responseCode = "400",
            description = "`INVALID_REQUEST`: callSessionId가 비었거나 64자 초과, memberId·startedAt·durationSeconds가 비어 있거나 durationSeconds가 음수(`errorMessage`에 사유). `MALFORMED_REQUEST_BODY`: 요청 본문이 올바른 JSON이 아니거나 필드 형식이 올바르지 않음",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "401",
            description = "`UNAUTHENTICATED`: Authorization 헤더가 없거나 Access Token이 유효하지 않음. `EXPIRED_TOKEN`: Access Token이 만료됨",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "404",
            description = "`MEMBER_NOT_FOUND`: 존재하지 않거나 삭제된 회원",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<CallHistoryResponse> recordCallHistory(@Valid CallHistoryRecordRequest request);

}
