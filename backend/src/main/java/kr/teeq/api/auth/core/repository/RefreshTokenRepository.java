package kr.teeq.api.auth.core.repository;

import java.util.Optional;
import java.util.UUID;
import kr.teeq.api.auth.core.entity.RefreshToken;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RefreshTokenRepository extends JpaRepository<RefreshToken, UUID> {

    Optional<RefreshToken> findByMemberId(UUID memberId);

    void deleteByMemberId(UUID memberId);

}
