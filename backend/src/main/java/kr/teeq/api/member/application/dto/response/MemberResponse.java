package kr.teeq.api.member.application.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.UUID;
import kr.teeq.api.member.core.entity.Member;

public record MemberResponse(
    @Schema(description = "회원 id(UUID)", example = "0192f3a4-5b6c-7d8e-9f01-23456789abcd")
    UUID memberId,

    @Schema(description = "이메일(소문자로 정규화된 값)", example = "user@example.com")
    String email,

    @Schema(description = "닉네임", example = "티큐")
    String nickname,

    @Schema(description = "AI 캐릭터 보유 여부. false면 앱이 온보딩 화면으로 보낸다", example = "true")
    boolean hasAiCharacter
) {

    public static MemberResponse from(Member member, boolean hasAiCharacter) {
        return new MemberResponse(member.getId(), member.getEmail(), member.getNickname(), hasAiCharacter);
    }

}
