package kr.co.teeq.api.call.application.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.call.application.dto.response.CallUsageResponse;
import kr.co.teeq.api.call.core.constant.CallUsageUnit;
import kr.co.teeq.api.common.application.exception.ErrorResponse;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestParam;

@Tag(name = "관리자 통화 사용량", description = "관리자 전용 통화 사용량 조회(ADMIN 권한 필요)")
public interface CallUsageAdminControllerDocs {

    @Operation(summary = "통화 사용량 조회",
        description = """
            기간별 통화 사용 시간(초)과 통화 횟수를 일별 또는 월별로 집계해 기간 오름차순으로 반환한다.
            `memberId`를 비우면 서비스 전체 사용량이고, 통화가 없는 기간은 0으로 채워진다.
            기간은 KST 기준이며 통화 시작 시각이 속한 기간에 집계한다. 통화 횟수에서 실패·대기 중 통화는 제외한다.
            일별(`DAY`)은 최대 93일, 월별(`MONTH`)은 최대 24개월(`from`, `to`가 속한 달 전체 포함)까지 조회할 수 있다.""")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "조회 성공. 기간 오름차순 목록"),
        @ApiResponse(responseCode = "400",
            description = "`INVALID_REQUEST`: `unit`, `from`, `to` 누락 또는 형식 오류(`unit`은 DAY, MONTH, 날짜는 yyyy-MM-dd), `from`이 `to`보다 늦음, 조회 기간이 단위별 최대치 초과",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "401",
            description = "`UNAUTHENTICATED`: Authorization 헤더가 없거나 Access Token이 유효하지 않음. `EXPIRED_TOKEN`: Access Token이 만료됨",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "403",
            description = "`ACCESS_DENIED`: ADMIN 권한이 없음",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "404",
            description = "`MEMBER_NOT_FOUND`: `memberId`에 해당하는 회원이 없거나 탈퇴함",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<List<CallUsageResponse>> getUsages(
        @Parameter(description = "집계 단위(DAY, MONTH)") @RequestParam("unit") CallUsageUnit unit,
        @Parameter(description = "조회 시작 날짜(KST, yyyy-MM-dd)", example = "2026-10-01")
        @RequestParam("from") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
        @Parameter(description = "조회 종료 날짜(KST, yyyy-MM-dd, 포함)", example = "2026-10-31")
        @RequestParam("to") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
        @Parameter(description = "대상 회원 ID. 비우면 서비스 전체")
        @RequestParam(value = "memberId", required = false) UUID memberId);

}
