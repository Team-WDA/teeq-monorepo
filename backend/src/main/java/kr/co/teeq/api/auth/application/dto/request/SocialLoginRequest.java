package kr.co.teeq.api.auth.application.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import kr.co.teeq.api.auth.core.constant.SocialType;

public record SocialLoginRequest(
    @NotNull(message = "소셜 로그인 제공자를 입력해 주세요.")
    @Schema(description = "소셜 로그인 제공자. 현재는 APPLE만 지원한다.", example = "APPLE")
    SocialType socialType,

    @NotBlank(message = "인증 정보를 입력해 주세요.")
    @Size(max = 4096, message = "인증 정보는 4096자 이하로 입력해 주세요.")
    @Schema(description = "제공자가 발급한 토큰 문자열(Apple은 identity token)", example = "eyJraWQiOiJ...")
    String credential
) {

}
