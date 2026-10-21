package kr.co.teeq.api.auth.application.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import kr.co.teeq.api.member.core.constant.MemberValidation;

public record SignUpRequest(
    @NotBlank(message = "이메일을 입력해 주세요.")
    @Email(message = "올바른 이메일 형식이 아닙니다.")
    @Size(max = 254, message = "이메일은 254자 이하로 입력해 주세요.")
    @Schema(description = "가입 이메일. 254자 이하, 앞뒤 공백 불가. 소문자로 정규화해 저장한다.", example = "user@example.com")
    String email,

    @NotBlank(message = "비밀번호를 입력해 주세요.")
    @Pattern(regexp = MemberValidation.PASSWORD_REGEX, message = MemberValidation.PASSWORD_MESSAGE)
    @Schema(description = "비밀번호. 영문과 숫자를 포함한 8~64자, 공백과 한글 불가(출력 가능한 ASCII만 허용)", example = "Teeq1234!")
    String password,

    @NotBlank(message = "닉네임을 입력해 주세요.")
    @Pattern(regexp = MemberValidation.NICKNAME_REGEX, message = MemberValidation.NICKNAME_MESSAGE)
    @Schema(description = "닉네임. 한글만 사용해 2~10자. 대소문자 구분 없이 중복 불가", example = "티큐")
    String nickname,

    @AssertTrue(message = "서비스 이용약관에 동의해 주세요.")
    @Schema(description = "서비스 이용약관 동의(필수). true여야 가입된다.", example = "true")
    boolean serviceTermsAgreed,

    @AssertTrue(message = "개인정보 수집·이용에 동의해 주세요.")
    @Schema(description = "개인정보 수집·이용 동의(필수). true여야 가입된다.", example = "true")
    boolean privacyPolicyAgreed
) {

}
