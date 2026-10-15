package kr.teeq.api.auth.infrastructure.properties;

import java.nio.charset.StandardCharsets;
import org.springframework.boot.context.properties.ConfigurationProperties;

// HS512 서명 키는 64바이트 이상이어야 하는데 jjwt는 서명 시점에야 실패하므로 기동 시 직접 검증한다
@ConfigurationProperties(prefix = "jwt")
public record JwtProperties(String secretKey, long accessExpMillis, long refreshExpMillis, String issuer) {

    private static final int MINIMUM_SECRET_KEY_BYTES = 64;

    public JwtProperties {
        if (secretKey == null || secretKey.isBlank()
            || secretKey.getBytes(StandardCharsets.UTF_8).length < MINIMUM_SECRET_KEY_BYTES) {
            throw new IllegalStateException("jwt.secret-key는 최소 64바이트여야 합니다");
        }
        if (accessExpMillis <= 0 || refreshExpMillis <= 0) {
            throw new IllegalStateException("jwt 만료 시간은 0보다 커야 합니다");
        }
        if (issuer == null || issuer.isBlank()) {
            throw new IllegalStateException("jwt.issuer가 비어 있습니다");
        }
    }

}
