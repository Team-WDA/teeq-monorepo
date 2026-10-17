package kr.co.teeq.api.member.application.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import kr.co.teeq.api.member.core.constant.MemberValidation;

public record ChangeNicknameRequest(
    @NotBlank(message = "닉네임을 입력해 주세요.")
    @Pattern(regexp = MemberValidation.NICKNAME_REGEX, message = MemberValidation.NICKNAME_MESSAGE)
    @Schema(description = "새 닉네임. 한글, 영문, 숫자만 사용해 2~10자. 자신의 닉네임을 대소문자만 바꾸는 것은 허용", example = "티큐2")
    String nickname
) {

}
