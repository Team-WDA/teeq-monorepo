package kr.co.teeq.api.auth.core.port;

import java.util.Locale;
import kr.co.teeq.api.member.core.constant.LoginType;

/**
 * 제공자가 검증해 준 사용자 정보. subject는 Firebase uid이며, 이메일은 앞뒤 공백을 제거하고 소문자로 정규화한다.
 */
public record VerifiedIdentity(LoginType loginType, String subject, String email) {

    public VerifiedIdentity {
        email = email == null ? null : email.trim().toLowerCase(Locale.ROOT);
    }

}
