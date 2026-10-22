package kr.co.teeq.api.admin.application.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import kr.co.teeq.api.member.core.constant.MemberValidation;

public record AdminPasswordResetRequest(
    @NotBlank(message = "새 비밀번호를 입력해 주세요.")
    @Pattern(regexp = MemberValidation.PASSWORD_REGEX, message = MemberValidation.PASSWORD_MESSAGE)
    String newPassword
) {

    // 비밀번호가 로그·예외 메시지에 실리지 않도록 마스킹한다
    @Override
    public String toString() {
        return "AdminPasswordResetRequest[newPassword=****]";
    }

}
