package kr.co.teeq.api.auth.infrastructure.config;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jws;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.time.Clock;
import java.time.Instant;
import java.util.Date;
import java.util.UUID;
import javax.crypto.SecretKey;
import kr.co.teeq.api.auth.core.port.IssuedRefreshToken;
import kr.co.teeq.api.auth.core.port.TokenProvider;
import kr.co.teeq.api.auth.infrastructure.properties.JwtProperties;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import org.springframework.stereotype.Component;

@Component
public class JwtProvider implements TokenProvider {

    private static final String TYPE_CLAIM = "type";
    private static final String ACCESS_TYPE = "access";
    private static final String REFRESH_TYPE = "refresh";

    private final JwtProperties jwtProperties;
    private final Clock clock;
    private final SecretKey secretKey;

    public JwtProvider(JwtProperties jwtProperties, Clock clock) {
        this.jwtProperties = jwtProperties;
        this.clock = clock;
        this.secretKey = Keys.hmacShaKeyFor(jwtProperties.secretKey().getBytes(StandardCharsets.UTF_8));
    }

    @Override
    public String issueAccessToken(UUID memberId) {
        Instant issuedAt = clock.instant();
        return build(memberId, ACCESS_TYPE, issuedAt, issuedAt.plusMillis(jwtProperties.accessExpMillis()));
    }

    @Override
    public IssuedRefreshToken issueRefreshToken(UUID memberId) {
        Instant issuedAt = clock.instant();
        Instant expiresAt = issuedAt.plusMillis(jwtProperties.refreshExpMillis());
        return new IssuedRefreshToken(build(memberId, REFRESH_TYPE, issuedAt, expiresAt), expiresAt);
    }

    @Override
    public UUID parseAccessToken(String token) {
        return parse(token, ACCESS_TYPE, ErrorCode.EXPIRED_TOKEN, ErrorCode.UNAUTHENTICATED);
    }

    @Override
    public UUID parseRefreshToken(String token) {
        return parse(token, REFRESH_TYPE, ErrorCode.INVALID_REFRESH_TOKEN, ErrorCode.INVALID_REFRESH_TOKEN);
    }

    // jti는 같은 초에 발급된 토큰도 서로 다르게 만들어 로테이션 때 이전 토큰과 값이 같아지는 것을 막는다
    private String build(UUID memberId, String type, Instant issuedAt, Instant expiresAt) {
        return Jwts.builder()
            .subject(memberId.toString())
            .claim(TYPE_CLAIM, type)
            .id(UUID.randomUUID().toString())
            .issuer(jwtProperties.issuer())
            .issuedAt(Date.from(issuedAt))
            .expiration(Date.from(expiresAt))
            .signWith(secretKey, Jwts.SIG.HS512)
            .compact();
    }

    private UUID parse(String token, String expectedType, ErrorCode expiredCode, ErrorCode invalidCode) {
        try {
            Jws<Claims> signedClaims = Jwts.parser()
                .verifyWith(secretKey)
                .requireIssuer(jwtProperties.issuer())
                .clock(() -> Date.from(clock.instant()))
                .build()
                .parseSignedClaims(token);
            if (!Jwts.SIG.HS512.getId().equals(signedClaims.getHeader().getAlgorithm())) {
                throw new CustomException(invalidCode);
            }
            Claims claims = signedClaims.getPayload();
            String subject = claims.getSubject();
            if (subject == null || !expectedType.equals(claims.get(TYPE_CLAIM, String.class))) {
                throw new CustomException(invalidCode);
            }
            return UUID.fromString(subject);
        } catch (ExpiredJwtException exception) {
            throw new CustomException(expiredCode, exception);
        } catch (JwtException | IllegalArgumentException exception) {
            throw new CustomException(invalidCode, exception);
        }
    }

}
