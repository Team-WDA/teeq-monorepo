package kr.co.teeq.api.auth.infrastructure.adapter;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwsHeader;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jws;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.LocatorAdapter;
import java.security.Key;
import java.security.PublicKey;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Collections;
import java.util.Date;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.atomic.AtomicReference;
import java.util.concurrent.locks.ReentrantLock;
import kr.co.teeq.api.auth.core.constant.AppleClientIds;
import kr.co.teeq.api.auth.core.port.SocialIdentity;
import kr.co.teeq.api.auth.core.port.SocialIdentityVerifier;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.constant.LoginType;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * Apple identity token(RS256 JWT)을 검증한다. 공개키는 {@code kid}별로 메모리에 캐시하고,
 * 모르는 {@code kid}가 오면 마지막 조회 후 일정 시간이 지났을 때만 다시 조회한다.
 */
@Slf4j
@Component
public class AppleSocialIdentityVerifier implements SocialIdentityVerifier {

    static final String ISSUER = "https://appleid.apple.com";
    private static final Duration MINIMUM_REFRESH_INTERVAL = Duration.ofMinutes(5);
    private static final String EMAIL_CLAIM = "email";
    private static final String EMAIL_VERIFIED_CLAIM = "email_verified";

    private final AppleJwksClient appleJwksClient;
    private final Clock clock;
    private final AtomicReference<Map<String, PublicKey>> cachedKeys = new AtomicReference<>(Map.of());
    // 가상 스레드가 캐리어에 고정되지 않도록 synchronized 대신 사용한다
    private final ReentrantLock refreshLock = new ReentrantLock();
    private Instant lastFetchedAt;

    public AppleSocialIdentityVerifier(AppleJwksClient appleJwksClient, Clock clock) {
        this.appleJwksClient = appleJwksClient;
        this.clock = clock;
    }

    @Override
    public LoginType loginType() {
        return LoginType.APPLE;
    }

    @Override
    public SocialIdentity verify(String credential) {
        try {
            Jws<Claims> signedClaims = Jwts.parser()
                .keyLocator(new LocatorAdapter<Key>() {
                    @Override
                    protected Key locate(JwsHeader header) {
                        return findKey(header.getKeyId());
                    }
                })
                .requireIssuer(ISSUER)
                .clock(() -> Date.from(clock.instant()))
                .build()
                .parseSignedClaims(credential);
            if (!Jwts.SIG.RS256.getId().equals(signedClaims.getHeader().getAlgorithm())
                || signedClaims.getPayload().getExpiration() == null
                || !hasAllowedAudience(signedClaims.getPayload())) {
                throw new CustomException(ErrorCode.SOCIAL_TOKEN_INVALID);
            }
            return toIdentity(signedClaims.getPayload());
        } catch (JwtException | IllegalArgumentException exception) {
            throw new CustomException(ErrorCode.SOCIAL_TOKEN_INVALID, exception);
        }
    }

    // 번들 ID와 Services ID 중 하나라도 audience에 포함되면 허용한다
    private boolean hasAllowedAudience(Claims claims) {
        Set<String> audience = claims.getAudience();
        return audience != null && !Collections.disjoint(audience, AppleClientIds.AUDIENCES);
    }

    // email 클레임은 없을 수 있다(재로그인 등). 있을 때만 email_verified를 확인한다
    private SocialIdentity toIdentity(Claims claims) {
        String subject = claims.getSubject();
        if (subject == null || subject.isBlank()) {
            throw new CustomException(ErrorCode.SOCIAL_TOKEN_INVALID);
        }
        Object email = claims.get(EMAIL_CLAIM);
        if (!(email instanceof String emailValue) || emailValue.isBlank()) {
            return new SocialIdentity(LoginType.APPLE, subject, null);
        }
        if (!isEmailVerified(claims.get(EMAIL_VERIFIED_CLAIM))) {
            throw new CustomException(ErrorCode.SOCIAL_TOKEN_INVALID);
        }
        return new SocialIdentity(LoginType.APPLE, subject, emailValue);
    }

    // Apple은 email_verified를 불리언 또는 "true" 문자열로 보낸다. 값이 없으면 확인된 것으로 본다
    private boolean isEmailVerified(Object emailVerified) {
        if (emailVerified == null) {
            return true;
        }
        return Boolean.TRUE.equals(emailVerified) || "true".equals(emailVerified);
    }

    private Key findKey(String keyId) {
        if (keyId == null) {
            throw new CustomException(ErrorCode.SOCIAL_TOKEN_INVALID);
        }
        PublicKey key = cachedKeys.get().get(keyId);
        if (key == null) {
            refreshKeysIfAllowed(keyId);
            key = cachedKeys.get().get(keyId);
        }
        if (key == null) {
            throw new CustomException(ErrorCode.SOCIAL_TOKEN_INVALID);
        }
        return key;
    }

    // 동시에 들어온 요청 중 하나만 조회하도록 직렬화하고, 먼저 들어온 요청이 이미 갱신했다면 다시 조회하지 않는다
    private void refreshKeysIfAllowed(String keyId) {
        refreshLock.lock();
        try {
            if (cachedKeys.get().containsKey(keyId)) {
                return;
            }
            Instant now = clock.instant();
            if (lastFetchedAt != null && now.isBefore(lastFetchedAt.plus(MINIMUM_REFRESH_INTERVAL))) {
                return;
            }
            cachedKeys.set(appleJwksClient.fetch());
            lastFetchedAt = now;
        } finally {
            refreshLock.unlock();
        }
    }

}
