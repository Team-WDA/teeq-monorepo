package kr.teeq.api.auth.application.dto.request;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import kr.teeq.api.member.core.constant.MemberValidation;

public record SignUpRequest(
    @NotBlank(message = "이메일을 입력해 주세요.")
    @Email(message = "올바른 이메일 형식이 아닙니다.")
    @Size(max = 254, message = "이메일은 254자 이하로 입력해 주세요.")
    String email,

    @NotBlank(message = "비밀번호를 입력해 주세요.")
    @Pattern(regexp = MemberValidation.PASSWORD_REGEX, message = MemberValidation.PASSWORD_MESSAGE)
    String password,

    @NotBlank(message = "닉네임을 입력해 주세요.")
    @Pattern(regexp = MemberValidation.NICKNAME_REGEX, message = MemberValidation.NICKNAME_MESSAGE)
    String nickname,

    @AssertTrue(message = "서비스 이용약관에 동의해 주세요.")
    boolean serviceTermsAgreed,

    @AssertTrue(message = "개인정보 수집·이용에 동의해 주세요.")
    boolean privacyPolicyAgreed
) {

}
