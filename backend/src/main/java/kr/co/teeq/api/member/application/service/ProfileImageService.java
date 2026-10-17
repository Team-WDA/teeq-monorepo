package kr.co.teeq.api.member.application.service;

import java.io.IOException;
import java.util.UUID;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.constant.ProfileImageFormat;
import kr.co.teeq.api.member.core.port.ProfileImageStoragePort;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

/**
 * 프로필 사진 교체와 삭제. 파일 쓰기는 DB 트랜잭션 밖에서 먼저 하고 DB 작업만 {@link ProfileImageCommandService}에 맡긴다.
 */
@Service
@RequiredArgsConstructor
public class ProfileImageService {

    static final long MAX_FILE_SIZE_BYTES = 5L * 1024 * 1024;

    private final ProfileImageStoragePort profileImageStoragePort;
    private final ProfileImageCommandService profileImageCommandService;

    public void replace(UUID memberId, MultipartFile image) {
        // 전역 multipart 한도가 커서, 내용을 읽기 전에 크기부터 확인한다
        if (image.getSize() > MAX_FILE_SIZE_BYTES) {
            throw new CustomException(ErrorCode.PROFILE_IMAGE_TOO_LARGE);
        }
        byte[] content = readContent(image);
        ProfileImageFormat format = ProfileImageFormat.detect(content)
            .orElseThrow(() -> new CustomException(ErrorCode.PROFILE_IMAGE_INVALID));
        String storageKey = UUID.randomUUID() + "." + format.extension();

        profileImageStoragePort.store(storageKey, content);
        try {
            profileImageCommandService.replace(memberId, storageKey, format.contentType(), content.length);
        } catch (RuntimeException exception) {
            // DB에 반영되지 않은 파일이 남지 않게 정리한다
            profileImageStoragePort.delete(storageKey);
            throw exception;
        }
    }

    public void delete(UUID memberId) {
        profileImageCommandService.delete(memberId);
    }

    private byte[] readContent(MultipartFile image) {
        if (image.isEmpty()) {
            throw new CustomException(ErrorCode.PROFILE_IMAGE_INVALID);
        }
        try {
            return image.getBytes();
        } catch (IOException exception) {
            throw new CustomException(ErrorCode.PROFILE_IMAGE_INVALID, exception);
        }
    }

}
