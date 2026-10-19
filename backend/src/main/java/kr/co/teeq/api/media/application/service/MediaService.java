package kr.co.teeq.api.media.application.service;

import java.io.IOException;
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
        // 전역 multipart 한도가 커서, 내용을 읽기 전에 크기부터 확인한다
        if (file.getSize() > category.maximumSizeBytes()) {
            throw new CustomException(category.tooLargeErrorCode());
        }
        byte[] content = readContent(category, file);
        ImageFormat format = ImageFormat.detect(content)
            .orElseThrow(() -> new CustomException(category.invalidErrorCode()));
        String key = UUID.randomUUID() + "." + format.extension();

        mediaStoragePort.store(category, key, content);
        return new StoredMedia(key, format.contentType(), content.length);
    }

    public void delete(MediaCategory category, String key) {
        mediaStoragePort.delete(category, key);
    }

    public String urlFor(MediaCategory category, String key) {
        String baseUrl = settingConfigService.getString(SettingKey.MEDIA_BASE_URL).replaceAll("/+$", "");
        return baseUrl + mediaStoragePort.publicPath(category, key);
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

}
