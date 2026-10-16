package kr.teeq.api.auth.application.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;

public record RefreshRequest(
    @NotBlank(message = "리프레시 토큰을 입력해 주세요.")
    @Schema(description = "로그인·가입·재발급 때 받은 가장 최근의 Refresh Token", example = "eyJhbGciOiJIUzUxMiJ9...")
    String refreshToken
) {

}
