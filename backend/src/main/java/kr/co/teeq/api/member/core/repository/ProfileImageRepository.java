package kr.co.teeq.api.member.core.repository;

import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.member.core.entity.ProfileImage;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProfileImageRepository extends JpaRepository<ProfileImage, UUID> {

    // 회원의 현재(활성) 프로필 사진
    Optional<ProfileImage> findByMemberIdAndDeletedFalse(UUID memberId);

}
