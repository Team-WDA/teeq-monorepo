package kr.co.teeq.api.auth.core.port;

import java.time.Instant;

public record IssuedRefreshToken(String token, Instant expiresAt) {

}
