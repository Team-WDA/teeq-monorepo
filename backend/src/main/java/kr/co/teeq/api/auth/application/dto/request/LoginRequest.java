package kr.co.teeq.api.auth.application.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record LoginRequest(
    @NotBlank(message = "인증 정보를 입력해 주세요.")
    @Size(max = 4096, message = "인증 정보는 4096자 이하로 입력해 주세요.")
    @Schema(description = "Firebase ID token", example = "eyJhbGciOiJSUzI1NiIs...")
    String credential
) {

}
