package kr.teeq.api.auth.infrastructure.config;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.jsonwebtoken.Jwts;
import java.nio.charset.StandardCharsets;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Date;
import java.util.UUID;
import javax.crypto.spec.SecretKeySpec;
import kr.teeq.api.auth.core.port.IssuedRefreshToken;
import kr.teeq.api.auth.infrastructure.properties.JwtProperties;
import kr.teeq.api.common.core.exception.CustomException;
import kr.teeq.api.common.core.exception.ErrorCode;
import org.junit.jupiter.api.Test;

class JwtProviderTest {

    private static final Instant NOW = Instant.parse("2026-10-16T00:00:00Z");
    private static final String SECRET = "unit-test-secret-key-0123456789-abcdefghijklmnopqrstuvwxyz-ABCDEFGHIJ";
    private static final String OTHER_SECRET = "other-test-secret-key-0123456789-abcdefghijklmnopqrstuvwxyz-ABCDEFGHI";
    private static final long ACCESS_MILLIS = Duration.ofDays(1).toMillis();
    private static final long REFRESH_MILLIS = Duration.ofDays(30).toMillis();
    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");

    private JwtProvider providerAt(Instant instant) {
        return providerAt(instant, SECRET, "teeq-test");
    }

    private JwtProvider providerAt(Instant instant, String secret, String issuer) {
        JwtProperties properties = new JwtProperties(secret, ACCESS_MILLIS, REFRESH_MILLIS, issuer);
        return new JwtProvider(properties, Clock.fixed(instant, ZoneOffset.UTC));
    }

    private void assertFailsWith(Runnable action, ErrorCode expected) {
        assertThatThrownBy(action::run)
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(expected));
    }

    @Test
    void accessToken_roundTrip_returnsMemberId() {
        JwtProvider provider = providerAt(NOW);

        String token = provider.issueAccessToken(MEMBER_ID);

        assertThat(provider.parseAccessToken(token)).isEqualTo(MEMBER_ID);
    }

    @Test
    void accessToken_afterExpiry_throwsExpiredToken() {
        String token = providerAt(NOW).issueAccessToken(MEMBER_ID);
        JwtProvider later = providerAt(NOW.plus(Duration.ofDays(1)).plusSeconds(1));

        assertFailsWith(() -> later.parseAccessToken(token), ErrorCode.EXPIRED_TOKEN);
    }

    @Test
    void accessToken_garbageOrForgedOrWrongIssuer_throwsUnauthenticated() {
        JwtProvider provider = providerAt(NOW);
        String signedWithOtherKey = providerAt(NOW, OTHER_SECRET, "teeq-test").issueAccessToken(MEMBER_ID);
        String wrongIssuer = providerAt(NOW, SECRET, "someone-else").issueAccessToken(MEMBER_ID);

        assertFailsWith(() -> provider.parseAccessToken("not-a-jwt"), ErrorCode.UNAUTHENTICATED);
        assertFailsWith(() -> provider.parseAccessToken(signedWithOtherKey), ErrorCode.UNAUTHENTICATED);
        assertFailsWith(() -> provider.parseAccessToken(wrongIssuer), ErrorCode.UNAUTHENTICATED);
    }

    @Test
    void accessToken_signedWithHs256_throwsUnauthenticated() {
        String token = Jwts.builder()
            .subject(MEMBER_ID.toString())
            .claim("type", "access")
            .issuer("teeq-test")
            .issuedAt(Date.from(NOW))
            .expiration(Date.from(NOW.plus(Duration.ofDays(1))))
            .signWith(new SecretKeySpec(SECRET.getBytes(StandardCharsets.UTF_8), "HmacSHA256"), Jwts.SIG.HS256)
            .compact();

        assertFailsWith(() -> providerAt(NOW).parseAccessToken(token), ErrorCode.UNAUTHENTICATED);
    }

    @Test
    void refreshToken_roundTrip_returnsMemberIdAndExpiry() {
        JwtProvider provider = providerAt(NOW);

        IssuedRefreshToken issued = provider.issueRefreshToken(MEMBER_ID);

        assertThat(provider.parseRefreshToken(issued.token())).isEqualTo(MEMBER_ID);
        assertThat(issued.expiresAt()).isEqualTo(NOW.plusMillis(REFRESH_MILLIS));
    }

    @Test
    void refreshToken_issuedAtSameInstant_isUnique() {
        JwtProvider provider = providerAt(NOW);

        String first = provider.issueRefreshToken(MEMBER_ID).token();
        String second = provider.issueRefreshToken(MEMBER_ID).token();

        assertThat(first).isNotEqualTo(second);
    }

    @Test
    void refreshToken_afterExpiry_throwsInvalidRefreshToken() {
        String token = providerAt(NOW).issueRefreshToken(MEMBER_ID).token();
        JwtProvider later = providerAt(NOW.plusMillis(REFRESH_MILLIS).plusSeconds(1));

        assertFailsWith(() -> later.parseRefreshToken(token), ErrorCode.INVALID_REFRESH_TOKEN);
    }

    @Test
    void tokenTypes_cannotBeUsedInPlaceOfEachOther() {
        JwtProvider provider = providerAt(NOW);
        String accessToken = provider.issueAccessToken(MEMBER_ID);
        String refreshToken = provider.issueRefreshToken(MEMBER_ID).token();

        assertFailsWith(() -> provider.parseAccessToken(refreshToken), ErrorCode.UNAUTHENTICATED);
        assertFailsWith(() -> provider.parseRefreshToken(accessToken), ErrorCode.INVALID_REFRESH_TOKEN);
    }

    @Test
    void properties_withShortSecretKey_failFast() {
        assertThatThrownBy(() -> new JwtProperties("too-short", ACCESS_MILLIS, REFRESH_MILLIS, "teeq-test"))
            .isInstanceOf(IllegalStateException.class);
    }

}
