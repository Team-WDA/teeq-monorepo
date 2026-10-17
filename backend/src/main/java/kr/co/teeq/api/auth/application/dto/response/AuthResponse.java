package kr.co.teeq.api.auth.application.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.UUID;
import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.member.core.entity.Member;

public record AuthResponse(
    @Schema(description = "Access Token(유효기간 1일). `Authorization: Bearer <값>` 헤더로 보낸다.", example = "eyJhbGciOiJIUzUxMiJ9...")
    String accessToken,

    @Schema(description = "Refresh Token(유효기간 30일). 재발급 요청 때 쓰며, 재발급할 때마다 새 값으로 교체해야 한다.", example = "eyJhbGciOiJIUzUxMiJ9...")
    String refreshToken,

    @Schema(description = "회원 id(UUID)", example = "0192f3a4-5b6c-7d8e-9f01-23456789abcd")
    UUID memberId,

    @Schema(description = "닉네임. NULL이면 가입 완료 화면으로 보낸다", example = "티큐", nullable = true)
    String nickname,

    @Schema(description = "AI 캐릭터 보유 여부. false면 앱이 온보딩 화면으로 보낸다", example = "true")
    boolean hasAiCharacter,

    @Schema(description = "로그인 방식(EMAIL, APPLE)", example = "EMAIL")
    LoginType loginType,

    @Schema(description = "프로필 사진 URL. 사진이 없으면 null", example = "/media/profile-images/0192f3a4.jpg", nullable = true)
    String profileImageUrl
) {

    public static AuthResponse of(String accessToken, String refreshToken, Member member, boolean hasAiCharacter,
        String profileImageUrl) {
        return new AuthResponse(accessToken, refreshToken, member.getId(), member.getNickname(), hasAiCharacter,
            member.getLoginType(), profileImageUrl);
    }

}
