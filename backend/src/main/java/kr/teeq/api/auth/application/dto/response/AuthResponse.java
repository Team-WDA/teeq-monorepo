package kr.teeq.api.auth.application.dto.response;

import java.util.UUID;
import kr.teeq.api.member.core.entity.Member;

public record AuthResponse(String accessToken, String refreshToken, UUID memberId, String nickname) {

    public static AuthResponse of(String accessToken, String refreshToken, Member member) {
        return new AuthResponse(accessToken, refreshToken, member.getId(), member.getNickname());
    }

}
