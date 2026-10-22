package kr.co.teeq.api.admin.application.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import kr.co.teeq.api.member.core.constant.AdminRole;
import kr.co.teeq.api.member.core.constant.MemberValidation;

public record AdminAccountCreateRequest(
    @NotBlank(message = "아이디를 입력해 주세요.")
    @Pattern(regexp = "^[A-Za-z0-9_.-]{3,30}$", message = "아이디는 영문, 숫자, 점, 밑줄, 하이픈으로 3~30자여야 합니다.")
    String username,

    @NotBlank(message = "초기 비밀번호를 입력해 주세요.")
    @Pattern(regexp = MemberValidation.PASSWORD_REGEX, message = MemberValidation.PASSWORD_MESSAGE)
    String password,

    @NotBlank(message = "이름을 입력해 주세요.")
    @Size(max = 30, message = "이름은 30자 이하로 입력해 주세요.")
    String name,

    @NotNull(message = "권한을 선택해 주세요.")
    AdminRole role
) {

    // 비밀번호가 로그·예외 메시지에 실리지 않도록 마스킹한다
    @Override
    public String toString() {
        return "AdminAccountCreateRequest[username=" + username + ", password=****, name=" + name
            + ", role=" + role + "]";
    }

}
