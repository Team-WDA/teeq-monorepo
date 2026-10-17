package kr.teeq.api.member.core.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import java.util.UUID;
import kr.teeq.api.common.core.entity.BaseEntity;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 회원의 프로필 사진 메타데이터. 회원당 활성 행(deleted = false) 하나가 현재 사진이며, 교체하거나 삭제하면 이전 행은 soft delete 된다.
 * 파일 자체는 저장소에 남기고 DB에는 저장 키만 둔다.
 */
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
@Table(name = "profile_image")
public class ProfileImage extends BaseEntity {

    @Column(nullable = false)
    private UUID memberId;

    @Column(nullable = false, length = 100)
    private String storageKey;

    @Column(nullable = false, length = 50)
    private String contentType;

    @Column(nullable = false)
    private long fileSize;

    private ProfileImage(UUID memberId, String storageKey, String contentType, long fileSize) {
        this.memberId = memberId;
        this.storageKey = storageKey;
        this.contentType = contentType;
        this.fileSize = fileSize;
    }

    public static ProfileImage of(UUID memberId, String storageKey, String contentType, long fileSize) {
        return new ProfileImage(memberId, storageKey, contentType, fileSize);
    }

}
