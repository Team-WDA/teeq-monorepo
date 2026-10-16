package kr.teeq.api.feedback.application.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import kr.teeq.api.common.application.exception.ErrorResponse;
import kr.teeq.api.feedback.application.dto.request.DetailedFeedbackRequest;
import kr.teeq.api.feedback.application.dto.request.RequiredFeedbackRequest;
import kr.teeq.api.feedback.application.dto.response.FeedbackStatusResponse;
import kr.teeq.api.feedback.application.dto.response.RequiredFeedbackResponse;
import kr.teeq.api.member.core.principal.AuthenticatedMember;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;

@Tag(name = "피드백", description = "통화 후 필수 피드백과 상세 피드백")
public interface FeedbackControllerDocs {

    @Operation(summary = "피드백 상태 조회",
        description = """
            통화 종료 후 피드백 화면을 구성하는 데 필요한 정보를 반환한다.
            `callIndex`는 회원의 통화 순번(실패한 통화 제외, 1부터), `previousCallRecallRequired`는 지난 통화 기억 문항을 보내야 하는지(두 번째 통화부터 true),
            `requiredFeedbackSubmitted`는 이 통화의 필수 피드백 제출 여부이다.""")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "조회 성공"),
        @ApiResponse(responseCode = "401",
            description = "`UNAUTHENTICATED`: Authorization 헤더가 없거나 Access Token이 유효하지 않거나 삭제된 회원임. `EXPIRED_TOKEN`: Access Token이 만료됨(토큰 재발급 후 재시도)",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "404",
            description = "`CALL_SESSION_NOT_FOUND`: 해당 통화 세션 ID의 기록이 없거나 본인의 통화가 아님",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "409",
            description = "`CALL_NOT_FEEDBACKABLE`: 종료 또는 만료 상태가 아닌 통화(진행 중이거나 실패한 통화). 통화 종료 보고가 처리되기 전(진행 중)이면 거절되므로 잠시 후 재시도",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<FeedbackStatusResponse> getFeedbackStatus(
        @Parameter(hidden = true) AuthenticatedMember authenticatedMember,
        @PathVariable("call-session-id") String callSessionId);

    @Operation(summary = "필수 피드백 제출",
        description = """
            통화 종료 후 필수 피드백을 제출한다. 통화당 한 번만 제출할 수 있다.
            지난 통화 기억(`previousCallRecall`)은 두 번째 통화부터 필수이고 첫 통화에서는 보내면 안 된다.
            어색했던 순간(`awkwardMoments`)은 중복할 수 없고 `NONE`은 단독으로만 선택할 수 있다.
            응답의 `detailedFeedbackInvited`가 true이면 이어서 상세 피드백을 받는다(세 번째 통화마다).""")
    @ApiResponses({
        @ApiResponse(responseCode = "201", description = "제출 성공"),
        @ApiResponse(responseCode = "400",
            description = "`INVALID_REQUEST`: 필수 값이 없거나 점수가 1~5 범위를 벗어남, 목록이 비어 있음(`errorMessage`에 사유). `MALFORMED_REQUEST_BODY`: 요청 본문이 올바른 JSON이 아니거나 정의되지 않은 선택지 값. `INVALID_FEEDBACK_ANSWER`: 지난 통화 기억 필수·금지 규칙 위반, 어색했던 순간 중복 또는 `NONE` 혼합",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "401",
            description = "`UNAUTHENTICATED`: Authorization 헤더가 없거나 Access Token이 유효하지 않거나 삭제된 회원임. `EXPIRED_TOKEN`: Access Token이 만료됨(토큰 재발급 후 재시도)",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "404",
            description = "`CALL_SESSION_NOT_FOUND`: 해당 통화 세션 ID의 기록이 없거나 본인의 통화가 아님",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "409",
            description = "`CALL_NOT_FEEDBACKABLE`: 종료 또는 만료 상태가 아닌 통화(통화 종료 보고가 처리되기 전(진행 중)이면 거절되므로 잠시 후 재시도). `FEEDBACK_ALREADY_SUBMITTED`: 이 통화의 필수 피드백을 이미 제출함(동시 중복 요청 포함)",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<RequiredFeedbackResponse> submitRequiredFeedback(
        @Parameter(hidden = true) AuthenticatedMember authenticatedMember,
        @PathVariable("call-session-id") String callSessionId,
        @Valid @RequestBody RequiredFeedbackRequest request);

    @Operation(summary = "상세 피드백 제출",
        description = """
            필수 피드백을 제출한 통화 중 상세 피드백 대상(세 번째 통화마다)인 통화에 상세 피드백을 제출한다. 통화당 한 번만 제출할 수 있다.
            `memoryNotApplicable`이 true이면 `memoryScore`와 `memoryReason`을 보내면 안 되고, false이면 `memoryScore`가 필수이다.
            `startReasons`는 중복할 수 없고 `startReasonOtherText`는 `OTHER`를 선택했을 때만 보낼 수 있다.
            공백뿐인 문자열은 값이 없는 것으로 처리한다.""")
    @ApiResponses({
        @ApiResponse(responseCode = "201", description = "제출 성공(본문 없음)"),
        @ApiResponse(responseCode = "400",
            description = "`INVALID_REQUEST`: 필수 값이 없거나 점수가 1~5 범위를 벗어남, 글자 수 초과, 목록이 비어 있음(`errorMessage`에 사유). `MALFORMED_REQUEST_BODY`: 요청 본문이 올바른 JSON이 아니거나 정의되지 않은 선택지 값. `INVALID_FEEDBACK_ANSWER`: 기억 문항 면제 조합 위반, 시작 이유 중복, `OTHER` 없이 기타 이유 입력",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "401",
            description = "`UNAUTHENTICATED`: Authorization 헤더가 없거나 Access Token이 유효하지 않거나 삭제된 회원임. `EXPIRED_TOKEN`: Access Token이 만료됨(토큰 재발급 후 재시도)",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "404",
            description = "`CALL_SESSION_NOT_FOUND`: 해당 통화 세션 ID의 기록이 없거나 본인의 통화가 아님",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "409",
            description = "`CALL_NOT_FEEDBACKABLE`: 종료 또는 만료 상태가 아닌 통화(통화 종료 보고가 처리되기 전(진행 중)이면 거절되므로 잠시 후 재시도). `REQUIRED_FEEDBACK_NOT_SUBMITTED`: 필수 피드백을 아직 제출하지 않음. `DETAILED_FEEDBACK_NOT_INVITED`: 상세 피드백 대상 통화가 아님. `FEEDBACK_ALREADY_SUBMITTED`: 이 통화의 상세 피드백을 이미 제출함(동시 중복 요청 포함)",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<Void> submitDetailedFeedback(
        @Parameter(hidden = true) AuthenticatedMember authenticatedMember,
        @PathVariable("call-session-id") String callSessionId,
        @Valid @RequestBody DetailedFeedbackRequest request);

}
