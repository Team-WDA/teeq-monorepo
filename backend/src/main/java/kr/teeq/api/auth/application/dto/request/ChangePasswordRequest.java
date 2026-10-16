package kr.teeq.api.auth.application.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import kr.teeq.api.member.core.constant.MemberValidation;

public record ChangePasswordRequest(
    @NotBlank(message = "현재 비밀번호를 입력해 주세요.")
    @Schema(description = "현재 비밀번호", example = "Teeq1234!")
    String currentPassword,

    @NotBlank(message = "새 비밀번호를 입력해 주세요.")
    @Pattern(regexp = MemberValidation.PASSWORD_REGEX, message = MemberValidation.PASSWORD_MESSAGE)
    @Schema(description = "새 비밀번호. 영문과 숫자를 포함한 8~64자, 공백과 한글 불가(출력 가능한 ASCII만 허용)", example = "Teeq5678!")
    String newPassword
) {

}
