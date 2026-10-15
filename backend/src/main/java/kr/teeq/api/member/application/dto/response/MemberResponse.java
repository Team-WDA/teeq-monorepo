package kr.teeq.api.member.application.dto.response;

import java.util.UUID;
import kr.teeq.api.member.core.entity.Member;

public record MemberResponse(UUID memberId, String email, String nickname) {

    public static MemberResponse from(Member member) {
        return new MemberResponse(member.getId(), member.getEmail(), member.getNickname());
    }

}
