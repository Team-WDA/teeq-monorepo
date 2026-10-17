package kr.co.teeq.api.auth.infrastructure.adapter;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

import io.jsonwebtoken.JwtBuilder;
import io.jsonwebtoken.Jwts;
import java.security.KeyPair;
import java.security.PublicKey;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Date;
import java.util.Map;
import kr.co.teeq.api.auth.core.port.SocialIdentity;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.constant.LoginType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class AppleSocialIdentityVerifierTest {

    private static final Instant NOW = Instant.parse("2026-10-17T00:00:00Z");
    private static final String KEY_ID = "test-key";

    @Mock
    private AppleJwksClient appleJwksClient;

    private final KeyPair keyPair = Jwts.SIG.RS256.keyPair().build();
    private MutableClock clock;
    private AppleSocialIdentityVerifier verifier;

    @BeforeEach
    void setUp() {
        clock = new MutableClock(NOW);
        verifier = new AppleSocialIdentityVerifier(appleJwksClient, clock);
    }

    private JwtBuilder validToken() {
        return Jwts.builder()
            .header().keyId(KEY_ID).and()
            .issuer(AppleSocialIdentityVerifier.ISSUER)
            .audience().add(AppleSocialIdentityVerifier.AUDIENCE).and()
            .subject("apple-subject")
            .claim("email", "Soyeon@Teeq.com")
            .issuedAt(Date.from(NOW))
            .expiration(Date.from(NOW.plusSeconds(600)));
    }

    private String sign(JwtBuilder builder) {
        return builder.signWith(keyPair.getPrivate(), Jwts.SIG.RS256).compact();
    }

    private void stubKeys() {
        given(appleJwksClient.fetch()).willReturn(Map.of(KEY_ID, keyPair.getPublic()));
    }

    private void assertFailsWith(String token, ErrorCode expected) {
        assertThatThrownBy(() -> verifier.verify(token))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(expected));
    }

    @Test
    void verify_validToken_returnsNormalizedIdentity() {
        stubKeys();

        SocialIdentity identity = verifier.verify(sign(validToken()));

        assertThat(identity).isEqualTo(new SocialIdentity(LoginType.APPLE, "apple-subject", "soyeon@teeq.com"));
    }

    @Test
    void verify_signedWithOtherKey_throwsTokenInvalid() {
        stubKeys();
        String token = validToken().signWith(Jwts.SIG.RS256.keyPair().build().getPrivate(), Jwts.SIG.RS256).compact();

        assertFailsWith(token, ErrorCode.SOCIAL_TOKEN_INVALID);
    }

    @Test
    void verify_expiredToken_throwsTokenInvalid() {
        stubKeys();
        String token = sign(validToken().expiration(Date.from(NOW.minusSeconds(60))));

        assertFailsWith(token, ErrorCode.SOCIAL_TOKEN_INVALID);
    }

    @Test
    void verify_missingExpiration_throwsTokenInvalid() {
        stubKeys();

        assertFailsWith(sign(validToken().expiration(null)), ErrorCode.SOCIAL_TOKEN_INVALID);
    }

    @Test
    void verify_wrongIssuerOrAudience_throwsTokenInvalid() {
        stubKeys();

        assertFailsWith(sign(validToken().issuer("https://evil.example.com")), ErrorCode.SOCIAL_TOKEN_INVALID);
        assertFailsWith(sign(validToken().audience().single("other.app")), ErrorCode.SOCIAL_TOKEN_INVALID);
    }

    @Test
    void verify_missingEmailOrSubject_throwsTokenInvalid() {
        stubKeys();

        assertFailsWith(sign(validToken().claim("email", null)), ErrorCode.SOCIAL_TOKEN_INVALID);
        assertFailsWith(sign(validToken().subject(null)), ErrorCode.SOCIAL_TOKEN_INVALID);
    }

    @Test
    void verify_emailVerifiedFalseIsRejected_andTrueAsBooleanOrStringIsAccepted() {
        stubKeys();

        assertFailsWith(sign(validToken().claim("email_verified", false)), ErrorCode.SOCIAL_TOKEN_INVALID);
        assertFailsWith(sign(validToken().claim("email_verified", "false")), ErrorCode.SOCIAL_TOKEN_INVALID);
        assertThat(verifier.verify(sign(validToken().claim("email_verified", true))).subject())
            .isEqualTo("apple-subject");
        assertThat(verifier.verify(sign(validToken().claim("email_verified", "true"))).subject())
            .isEqualTo("apple-subject");
    }

    @Test
    void verify_otherAlgorithm_throwsTokenInvalid() {
        stubKeys();
        String token = validToken().signWith(keyPair.getPrivate(), Jwts.SIG.RS512).compact();

        assertFailsWith(token, ErrorCode.SOCIAL_TOKEN_INVALID);
    }

    @Test
    void verify_malformedToken_throwsTokenInvalid() {
        assertFailsWith("not-a-jwt", ErrorCode.SOCIAL_TOKEN_INVALID);
    }

    @Test
    void verify_unknownKeyId_refetchesOnlyAfterTheMinimumInterval() {
        stubKeys();
        String unknownKeyToken = Jwts.builder()
            .header().keyId("unknown-key").and()
            .issuer(AppleSocialIdentityVerifier.ISSUER)
            .audience().add(AppleSocialIdentityVerifier.AUDIENCE).and()
            .subject("apple-subject")
            .claim("email", "soyeon@teeq.com")
            .expiration(Date.from(NOW.plusSeconds(600)))
            .signWith(keyPair.getPrivate(), Jwts.SIG.RS256)
            .compact();

        assertFailsWith(unknownKeyToken, ErrorCode.SOCIAL_TOKEN_INVALID);
        assertFailsWith(unknownKeyToken, ErrorCode.SOCIAL_TOKEN_INVALID);
        verify(appleJwksClient, times(1)).fetch();

        clock.advance(Duration.ofMinutes(5));
        assertFailsWith(unknownKeyToken, ErrorCode.SOCIAL_TOKEN_INVALID);
        verify(appleJwksClient, times(2)).fetch();
    }

    @Test
    void verify_cachedKey_doesNotFetchAgain() {
        stubKeys();
        String token = sign(validToken());

        verifier.verify(token);
        verifier.verify(token);

        verify(appleJwksClient, times(1)).fetch();
    }

    @Test
    void verify_keyFetchFailure_throwsServerUnavailable() {
        given(appleJwksClient.fetch()).willThrow(new CustomException(ErrorCode.SOCIAL_SERVER_UNAVAILABLE));

        assertFailsWith(sign(validToken()), ErrorCode.SOCIAL_SERVER_UNAVAILABLE);
    }

    @Test
    void verify_keyFetchFailureThenRecovery_succeedsOnNextCall() {
        PublicKey publicKey = keyPair.getPublic();
        given(appleJwksClient.fetch())
            .willThrow(new CustomException(ErrorCode.SOCIAL_SERVER_UNAVAILABLE))
            .willReturn(Map.of(KEY_ID, publicKey));
        String token = sign(validToken());

        assertFailsWith(token, ErrorCode.SOCIAL_SERVER_UNAVAILABLE);
        assertThat(verifier.verify(token).subject()).isEqualTo("apple-subject");
    }

    private static final class MutableClock extends Clock {

        private Instant instant;

        private MutableClock(Instant instant) {
            this.instant = instant;
        }

        private void advance(Duration duration) {
            instant = instant.plus(duration);
        }

        @Override
        public java.time.ZoneId getZone() {
            return ZoneOffset.UTC;
        }

        @Override
        public Clock withZone(java.time.ZoneId zone) {
            return this;
        }

        @Override
        public Instant instant() {
            return instant;
        }

    }

}
