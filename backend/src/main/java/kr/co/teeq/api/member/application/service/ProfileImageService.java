package kr.co.teeq.api.member.application.service;

import kr.co.teeq.api.media.application.service.MediaService;
import kr.co.teeq.api.media.core.constant.MediaCategory;
import kr.co.teeq.api.media.core.model.StoredMedia;
import kr.co.teeq.api.member.core.entity.Member;
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

    public void replace(Member member, MultipartFile image) {
        StoredMedia stored = mediaService.storeImage(MediaCategory.PROFILE_IMAGE, image);
        try {
            profileImageCommandService.replace(member, stored.key(), stored.contentType(), stored.sizeBytes());
        } catch (RuntimeException exception) {
            // DB에 반영되지 않은 파일이 남지 않게 정리한다
            mediaService.delete(MediaCategory.PROFILE_IMAGE, stored.key());
            throw exception;
        }
    }

    public void delete(Member member) {
        profileImageCommandService.delete(member);
    }

}
