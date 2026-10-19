package kr.co.teeq.api.member.application.service;

import java.util.UUID;
import kr.co.teeq.api.media.application.service.MediaService;
import kr.co.teeq.api.media.core.constant.MediaCategory;
import kr.co.teeq.api.media.core.model.StoredMedia;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

/**
 * 프로필 사진 교체와 삭제. 파일 쓰기는 DB 트랜잭션 밖에서 먼저 하고 DB 작업만 {@link ProfileImageCommandService}에 맡긴다.
 */
@Service
@RequiredArgsConstructor
public class ProfileImageService {

    private final MediaService mediaService;
    private final ProfileImageCommandService profileImageCommandService;

    public void replace(UUID memberId, MultipartFile image) {
        StoredMedia stored = mediaService.storeImage(MediaCategory.PROFILE_IMAGE, image);
        try {
            profileImageCommandService.replace(memberId, stored.key(), stored.contentType(), stored.sizeBytes());
        } catch (RuntimeException exception) {
            // DB에 반영되지 않은 파일이 남지 않게 정리한다
            mediaService.delete(MediaCategory.PROFILE_IMAGE, stored.key());
            throw exception;
        }
    }

    public void delete(UUID memberId) {
        profileImageCommandService.delete(memberId);
    }

}
