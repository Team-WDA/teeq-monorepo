package kr.co.teeq.api.auth.core.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import kr.co.teeq.api.common.core.entity.BaseEntity;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 회원당 하나만 유지하는 Refresh Token. 이력이 필요 없어 soft delete 대신 행을 삭제한다(soft delete 규칙의 예외).
 */
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
@Table(name = "refresh_token")
public class RefreshToken extends BaseEntity {

    @Column(nullable = false)
    private UUID memberId;

    @Column(nullable = false)
    private String token;

    @Column(nullable = false)
    private Instant expiresAt;

    @Builder
    private RefreshToken(UUID memberId, String token, Instant expiresAt) {
        this.memberId = memberId;
        this.token = token;
        this.expiresAt = expiresAt;
    }

    public void rotate(String token, Instant expiresAt) {
        this.token = token;
        this.expiresAt = expiresAt;
    }

}
