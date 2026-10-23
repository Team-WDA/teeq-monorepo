package kr.co.teeq.api.auth.application.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import kr.co.teeq.api.member.core.constant.MemberValidation;

public record SocialSignUpRequest(
    @NotBlank(message = "인증 정보를 입력해 주세요.")
    @Size(max = 4096, message = "인증 정보는 4096자 이하로 입력해 주세요.")
    @Schema(description = "Firebase ID token", example = "eyJhbGciOiJSUzI1NiIs...")
    String credential,

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
