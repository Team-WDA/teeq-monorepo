package kr.co.teeq.api.auth.application.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;

public record LoginRequest(
    @NotBlank(message = "이메일을 입력해 주세요.")
    @Schema(description = "로그인 이메일. 앞뒤 공백은 제거하고 소문자로 바꿔 비교한다.", example = "user@example.com")
    String email,

    @NotBlank(message = "비밀번호를 입력해 주세요.")
    @Schema(description = "비밀번호", example = "Teeq1234!")
    String password
) {

}
