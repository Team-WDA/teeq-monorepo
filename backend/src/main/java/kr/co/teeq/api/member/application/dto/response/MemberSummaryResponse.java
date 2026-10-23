package kr.co.teeq.api.member.application.dto.response;

import java.time.Instant;
import java.util.UUID;
import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.member.core.entity.Member;

public record MemberSummaryResponse(
    UUID id,
    String nickname,
    String email,
    LoginType loginType,
    Instant createdAt
) {

    public static MemberSummaryResponse from(Member member) {
        return new MemberSummaryResponse(member.getId(), member.getNickname(), member.getEmail(),
            member.getLoginType(), member.getCreatedAt());
    }

}
