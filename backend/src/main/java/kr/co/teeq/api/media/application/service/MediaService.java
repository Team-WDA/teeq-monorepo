package kr.co.teeq.api.media.application.service;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.media.core.constant.ImageFormat;
import kr.co.teeq.api.media.core.constant.MediaCategory;
import kr.co.teeq.api.media.core.model.StoredMedia;
import kr.co.teeq.api.media.core.port.MediaStoragePort;
import kr.co.teeq.api.setting.application.service.SettingConfigService;
import kr.co.teeq.api.setting.core.constant.SettingKey;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

/**
 * 미디어 파일 저장·삭제와 공개 URL 계산. DB 작업은 하지 않으므로 호출한 쪽이 트랜잭션 밖에서 먼저 저장한다.
 */
@Service
@RequiredArgsConstructor
public class MediaService {

    private final MediaStoragePort mediaStoragePort;
    private final SettingConfigService settingConfigService;

    public StoredMedia storeImage(MediaCategory category, MultipartFile file) {
        return storeValidated(category, validate(category, file));
    }

    /**
     * 여러 이미지를 저장한다. 모든 파일을 먼저 검증해 하나라도 잘못되면 한 장도 올리지 않고,
     * 저장 중 실패하면 이미 올린 파일을 지운 뒤 예외를 다시 던진다. 반환 순서는 입력 순서와 같다.
     */
    public List<StoredMedia> storeImages(MediaCategory category, List<MultipartFile> files) {
        List<ValidatedImage> validatedImages = files.stream()
            .map(file -> validate(category, file))
            .toList();

        List<StoredMedia> storedMedias = new ArrayList<>();
        try {
            for (ValidatedImage validatedImage : validatedImages) {
                storedMedias.add(storeValidated(category, validatedImage));
            }
        } catch (RuntimeException exception) {
            deleteAll(category, storedMedias.stream().map(StoredMedia::key).toList());
            throw exception;
        }
        return storedMedias;
    }

    public void delete(MediaCategory category, String key) {
        mediaStoragePort.delete(category, key);
    }

    public void deleteAll(MediaCategory category, List<String> keys) {
        keys.forEach(key -> delete(category, key));
    }

    public String urlFor(MediaCategory category, String key) {
        String baseUrl = settingConfigService.getString(SettingKey.MEDIA_BASE_URL).replaceAll("/+$", "");
        return baseUrl + mediaStoragePort.publicPath(category, key);
    }

    private ValidatedImage validate(MediaCategory category, MultipartFile file) {
        // 전역 multipart 한도가 커서, 내용을 읽기 전에 크기부터 확인한다
        if (file.getSize() > category.maximumSizeBytes()) {
            throw new CustomException(category.tooLargeErrorCode());
        }
        byte[] content = readContent(category, file);
        ImageFormat format = ImageFormat.detect(content)
            .orElseThrow(() -> new CustomException(category.invalidErrorCode()));
        return new ValidatedImage(content, format);
    }

    private StoredMedia storeValidated(MediaCategory category, ValidatedImage validatedImage) {
        String key = UUID.randomUUID() + "." + validatedImage.format().extension();
        mediaStoragePort.store(category, key, validatedImage.content());
        return new StoredMedia(key, validatedImage.format().contentType(), validatedImage.content().length);
    }

    private byte[] readContent(MediaCategory category, MultipartFile file) {
        if (file.isEmpty()) {
            throw new CustomException(category.invalidErrorCode());
        }
        try {
            return file.getBytes();
        } catch (IOException exception) {
            throw new CustomException(category.invalidErrorCode(), exception);
        }
    }

    // 검증을 마친 이미지의 내용과 판별된 형식
    private record ValidatedImage(byte[] content, ImageFormat format) {

    }

}
