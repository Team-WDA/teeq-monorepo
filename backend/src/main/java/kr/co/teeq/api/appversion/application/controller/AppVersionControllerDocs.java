package kr.co.teeq.api.appversion.application.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import kr.co.teeq.api.appversion.application.dto.response.AppVersionCheckResponse;
import kr.co.teeq.api.appversion.core.constant.AppPlatform;
import kr.co.teeq.api.common.application.exception.ErrorResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestParam;

@Tag(name = "앱 버전", description = "앱 최소 지원 버전 확인")
public interface AppVersionControllerDocs {

    @Operation(summary = "앱 최소 버전 확인",
        description = """
            인증 없이 호출한다. 앱 버전이 플랫폼별 최소 지원 버전보다 낮으면 `updateRequired`가 true이며,
            이때 앱은 `storeUrl`로 업데이트를 안내한다. 같은 버전이면 false다.
            `appVersion`은 빌드 번호(`+N`) 없이 `x.y.z` 형식이어야 한다.""")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "확인 성공"),
        @ApiResponse(responseCode = "400",
            description = "`INVALID_REQUEST`: `platform`이 ANDROID/IOS가 아니거나(소문자 포함) 누락됨, `appVersion`이 `x.y.z` 형식이 아니거나 누락됨",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    ResponseEntity<AppVersionCheckResponse> check(
        @Parameter(description = "앱 플랫폼(ANDROID, IOS)", example = "ANDROID") @RequestParam AppPlatform platform,
        @Parameter(description = "현재 앱 버전(x.y.z)", example = "1.2.3") @RequestParam String appVersion);

}
