package kr.teeq.api.auth.core.port;

import java.util.UUID;

/**
 * 토큰 발급과 검증 port. 구현은 infrastructure의 JWT 구현체다.
 * 파싱 실패는 CustomException으로 던진다(AT 만료는 EXPIRED_TOKEN, 그 외 AT 실패는 UNAUTHENTICATED,
 * RT는 모든 실패가 INVALID_REFRESH_TOKEN).
 */
public interface TokenProvider {

    String issueAccessToken(UUID memberId);

    IssuedRefreshToken issueRefreshToken(UUID memberId);

    UUID parseAccessToken(String token);

    UUID parseRefreshToken(String token);

}
