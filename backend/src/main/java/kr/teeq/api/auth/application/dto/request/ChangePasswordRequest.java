package kr.teeq.api.auth.application.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import kr.teeq.api.member.core.constant.MemberValidation;

public record ChangePasswordRequest(
    @NotBlank(message = "현재 비밀번호를 입력해 주세요.")
    String currentPassword,

    @NotBlank(message = "새 비밀번호를 입력해 주세요.")
    @Pattern(regexp = MemberValidation.PASSWORD_REGEX, message = MemberValidation.PASSWORD_MESSAGE)
    String newPassword
) {

}
