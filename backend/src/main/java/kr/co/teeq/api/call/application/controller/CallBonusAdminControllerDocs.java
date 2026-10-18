package kr.co.teeq.api.call.application.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.call.application.dto.request.CallBonusGrantRequest;
import kr.co.teeq.api.call.application.dto.response.CallBonusResponse;
import kr.co.teeq.api.common.application.exception.ErrorResponse;
import kr.co.teeq.api.member.core.principal.AuthenticatedMember;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;

@Tag(name = "관리자 추가 통화 시간", description = "관리자 전용 하루 추가 통화 시간 부여, 조회, 취소(ADMIN 권한 필요)")
public interface CallBonusAdminControllerDocs {

    @Operation(summary = "하루 추가 통화 시간 부여",
        description = """
            회원에게 특정 날짜(KST)에만 유효한 추가 통화 시간을 부여한다. 같은 회원과 날짜에 여러 건을 부여하면 합산되고, 날짜가 지나면 자동으로 적용되지 않는다.
            `bonusDate`를 비우면 오늘(KST)이며 과거 날짜는 부여할 수 없다. 부여한 관리자는 자동으로 기록된다.""")
    @ApiResponses({
        @ApiResponse(responseCode = "201", description = "부여 성공. 생성된 항목 반환"),
        @ApiResponse(responseCode = "400",
            description = "`INVALID_REQUEST`: 시간이 1~3600초 범위를 벗어남, 사유가 비어 있거나 200자 초과, 과거 날짜(`errorMessage`는 세부 사유 없이 일반 문구). `MALFORMED_REQUEST_BODY`: 요청 본문이 올바른 JSON이 아니거나 날짜 형식이 올바르지 않음",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "401",
            description = "`UNAUTHENTICATED`: Authorization 헤더가 없거나 Access Token이 유효하지 않음. `EXPIRED_TOKEN`: Access Token이 만료됨",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "403",
            description = "`ACCESS_DENIED`: ADMIN 권한이 없음",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "404",
            description = "`MEMBER_NOT_FOUND`: 대상 회원이 없거나 탈퇴함",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<CallBonusResponse> grant(
        @Parameter(hidden = true) AuthenticatedMember authenticatedMember,
        @Parameter(description = "대상 회원 ID") @PathVariable("member-id") UUID memberId,
        @Valid @RequestBody CallBonusGrantRequest request);

    @Operation(summary = "추가 통화 시간 부여 내역 조회",
        description = """
            회원의 추가 통화 시간 부여 내역을 부여 시각 내림차순으로 반환한다. 취소된 항목도 포함하며 `canceled`, `canceledAt`, `canceledByMemberId`로 구분한다.""")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "조회 성공. 내역이 없으면 빈 배열"),
        @ApiResponse(responseCode = "401",
            description = "`UNAUTHENTICATED`: Authorization 헤더가 없거나 Access Token이 유효하지 않음. `EXPIRED_TOKEN`: Access Token이 만료됨",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "403",
            description = "`ACCESS_DENIED`: ADMIN 권한이 없음",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<List<CallBonusResponse>> getAll(
        @Parameter(description = "대상 회원 ID") @PathVariable("member-id") UUID memberId);

    @Operation(summary = "추가 통화 시간 취소",
        description = """
            부여한 추가 통화 시간을 취소한다. 취소한 관리자가 기록되고 이력은 조회 API에 남는다.""")
    @ApiResponses({
        @ApiResponse(responseCode = "204", description = "취소 성공"),
        @ApiResponse(responseCode = "401",
            description = "`UNAUTHENTICATED`: Authorization 헤더가 없거나 Access Token이 유효하지 않음. `EXPIRED_TOKEN`: Access Token이 만료됨",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "403",
            description = "`ACCESS_DENIED`: ADMIN 권한이 없음",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "404",
            description = "`CALL_BONUS_NOT_FOUND`: 추가 시간이 없거나 이미 취소됐거나 해당 회원의 항목이 아님",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<Void> cancel(
        @Parameter(hidden = true) AuthenticatedMember authenticatedMember,
        @Parameter(description = "대상 회원 ID") @PathVariable("member-id") UUID memberId,
        @Parameter(description = "추가 통화 시간 ID") @PathVariable("call-bonus-id") UUID callBonusId);

}
