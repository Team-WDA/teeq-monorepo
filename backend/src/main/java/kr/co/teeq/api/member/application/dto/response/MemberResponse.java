package kr.co.teeq.api.member.application.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.UUID;
import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.member.core.entity.Member;

public record MemberResponse(
    @Schema(description = "회원 id(UUID)", example = "0192f3a4-5b6c-7d8e-9f01-23456789abcd")
    UUID memberId,

    @Schema(description = "이메일(Firebase 토큰의 값, 소문자로 정규화)", example = "user@example.com")
    String email,

    @Schema(description = "닉네임", example = "티크")
    String nickname,

    @Schema(description = "AI 캐릭터 보유 여부. false면 앱이 온보딩 화면으로 보낸다", example = "true")
    boolean hasAiCharacter,

    @Schema(description = "로그인 방식(APPLE, GOOGLE, EMAIL)", example = "GOOGLE")
    LoginType loginType,

    @Schema(description = "프로필 사진 절대 URL. 사진이 없으면 null",
        example = "https://api.teeq.co.kr/media/profile-images/0192f3a4.jpg", nullable = true)
    String profileImageUrl
) {

    public static MemberResponse from(Member member, boolean hasAiCharacter, String profileImageUrl) {
        return new MemberResponse(member.getId(), member.getEmail(), member.getNickname(), hasAiCharacter,
            member.getLoginType(), profileImageUrl);
    }

}
