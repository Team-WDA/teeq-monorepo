package kr.co.teeq.api.setting.application.controller;

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
import kr.co.teeq.api.setting.application.dto.request.SettingConfigUpdateRequest;
import kr.co.teeq.api.setting.application.dto.response.SettingConfigResponse;
import org.springframework.http.ResponseEntity;

@Tag(name = "관리자 설정", description = "관리자 전용 동적 설정 조회와 수정(관리자 로그인 세션 필요)")
public interface SettingConfigAdminControllerDocs {

    @Operation(summary = "동적 설정 목록 조회",
        description = """
            코드에 정의된 모든 설정 키와 현재 값을 반환한다. DB에 저장된 값이 없는 키는 기본값을 반환하며 `updatedAt`이 null이다.""")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "조회 성공"),
        @ApiResponse(responseCode = "401",
            description = "`UNAUTHENTICATED`: 로그인 세션이 없음",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<List<SettingConfigResponse>> getAll();

    @Operation(summary = "동적 설정 값 수정",
        description = """
            코드에 정의된 키의 값을 수정한다. 키를 새로 만들거나 삭제하는 API는 없다. 값은 키의 타입(INT, BOOLEAN, STRING)과 범위에 맞아야 한다.""")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "수정 성공. 갱신된 항목 반환"),
        @ApiResponse(responseCode = "400",
            description = "`INVALID_REQUEST`: value가 비어 있음. `INVALID_SETTING_VALUE`: 값이 키의 타입 또는 범위에 맞지 않음. `MALFORMED_REQUEST_BODY`: 요청 본문이 올바른 JSON이 아님",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "401",
            description = "`UNAUTHENTICATED`: 로그인 세션이 없음",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "403",
            description = "`ACCESS_DENIED`: 관리자 권한이 없거나 CSRF 토큰이 없거나 올바르지 않음",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "404",
            description = "`SETTING_CONFIG_NOT_FOUND`: 코드에 정의되지 않은 설정 키",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<SettingConfigResponse> update(
        @Parameter(description = "설정 키", example = "CALL_SESSION_LIMIT_SECONDS") String key,
        @Valid SettingConfigUpdateRequest request);

}
