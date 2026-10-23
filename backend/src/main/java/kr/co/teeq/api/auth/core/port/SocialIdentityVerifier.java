package kr.co.teeq.api.auth.core.port;

/**
 * 소셜 로그인 토큰을 검증하는 외부 연동 port. 구현체는 하나지만, application이 infrastructure를 직접 import하지
 * 못하는 계층 규칙 때문에 port로 둔다.
 */
public interface SocialIdentityVerifier {

    /**
     * 토큰을 검증하고 사용자 정보를 돌려준다.
     *
     * @throws kr.co.teeq.api.common.core.exception.CustomException 토큰이 올바르지 않으면 SOCIAL_TOKEN_INVALID,
     *     검증 서버와 통신할 수 없으면 SOCIAL_SERVER_UNAVAILABLE
     */
    SocialIdentity verify(String credential);

}
