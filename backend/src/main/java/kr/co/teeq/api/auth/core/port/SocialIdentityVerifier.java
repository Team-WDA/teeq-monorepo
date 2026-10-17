package kr.co.teeq.api.auth.core.port;

import kr.co.teeq.api.member.core.constant.LoginType;

/**
 * 소셜 제공자의 토큰을 검증하는 외부 연동 port. 제공자마다 구현체가 하나씩 있다.
 */
public interface SocialIdentityVerifier {

    LoginType loginType();

    /**
     * 토큰을 검증하고 사용자 정보를 돌려준다.
     *
     * @throws kr.co.teeq.api.common.core.exception.CustomException 토큰이 올바르지 않으면 SOCIAL_TOKEN_INVALID,
     *     제공자 서버와 통신할 수 없으면 SOCIAL_SERVER_UNAVAILABLE
     */
    SocialIdentity verify(String credential);

}
