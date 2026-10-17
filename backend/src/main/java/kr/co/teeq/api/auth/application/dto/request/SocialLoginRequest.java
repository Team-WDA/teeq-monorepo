package kr.co.teeq.api.auth.application.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import kr.co.teeq.api.auth.core.constant.SocialType;
import kr.co.teeq.api.member.core.constant.MemberValidation;

public record SocialLoginRequest(
    @NotNull(message = "소셜 로그인 제공자를 입력해 주세요.")
    @Schema(description = "소셜 로그인 제공자. 현재는 APPLE만 지원한다.", example = "APPLE")
    SocialType socialType,

    @NotBlank(message = "인증 정보를 입력해 주세요.")
    @Size(max = 4096, message = "인증 정보는 4096자 이하로 입력해 주세요.")
    @Schema(description = "제공자가 발급한 토큰 문자열(Apple은 identity token)", example = "eyJraWQiOiJ...")
    String credential,

    @Pattern(regexp = MemberValidation.NICKNAME_REGEX, message = MemberValidation.NICKNAME_MESSAGE)
    @Schema(description = "닉네임. 신규 가입일 때 필수. 한글, 영문, 숫자만 사용해 2~10자", example = "티큐", nullable = true)
    String nickname,

    @AssertTrue(message = "서비스 이용약관에 동의해 주세요.")
    @Schema(description = "서비스 이용약관 동의. 신규 가입일 때 필수이며 보낸다면 true여야 한다.", example = "true", nullable = true)
    Boolean serviceTermsAgreed,

    @AssertTrue(message = "개인정보 수집·이용에 동의해 주세요.")
    @Schema(description = "개인정보 수집·이용 동의. 신규 가입일 때 필수이며 보낸다면 true여야 한다.", example = "true", nullable = true)
    Boolean privacyPolicyAgreed
) {

}
