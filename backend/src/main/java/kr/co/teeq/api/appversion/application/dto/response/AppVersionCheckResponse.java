package kr.co.teeq.api.appversion.application.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;

/**
 * 앱 최소 지원 버전 확인 결과 응답.
 */
public record AppVersionCheckResponse(
    @Schema(description = "업데이트가 필요한지 여부. 앱 버전이 최소 지원 버전보다 낮으면 true", example = "true")
    boolean updateRequired,
    @Schema(description = "해당 플랫폼의 최소 지원 버전(x.y.z)", example = "1.3.0")
    String minimumVersion,
    @Schema(description = "해당 플랫폼의 스토어 주소", example = "https://play.google.com/store/apps/details?id=kr.co.teeq.app")
    String storeUrl
) {

}
