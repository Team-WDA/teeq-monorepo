package kr.co.teeq.api.media.infrastructure.adapter;

import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.media.core.constant.ImageFormat;
import kr.co.teeq.api.media.core.constant.MediaCategory;
import kr.co.teeq.api.media.core.port.MediaStoragePort;
import kr.co.teeq.api.media.infrastructure.properties.S3MediaProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Component;
import software.amazon.awssdk.core.exception.SdkException;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

/**
 * 미디어를 S3 버킷에 {@code {keyPrefix}{도메인}/{디렉터리}/{저장 키}} 객체로 저장한다. 공개 경로는 CloudFront가 서빙하는
 * {@code /{도메인}/{디렉터리}/{저장 키}}이며, 환경 prefix는 CloudFront 오리진 경로가 대신한다.
 * {@link Primary}로 선택된다. 볼륨 저장소({@link VolumeMediaStorage})로 되돌리려면 {@link Primary}만 옮기면 되지만,
 * DB에는 저장소 출처를 두지 않고 파일을 복사해 두지도 않으므로 S3를 쓰는 동안 올라간 파일은 되돌린 뒤 볼륨에서 찾을 수 없다.
 * 되돌릴 때는 그 파일을 볼륨으로 옮기는 작업이 따로 필요하다.
 */
@Slf4j
@Primary
@Component
@RequiredArgsConstructor
public class S3MediaStorage implements MediaStoragePort {

    // 저장 키가 매번 새 UUID라 내용이 바뀌지 않으므로 장기 캐시해도 안전하다
    private static final String CACHE_CONTROL = "public, max-age=31536000, immutable";
    private static final String PATH_SEPARATOR = "/";
    private static final char EXTENSION_SEPARATOR = '.';

    private final S3Client s3Client;
    private final S3MediaProperties properties;

    @Override
    public void store(MediaCategory category, String key, byte[] content) {
        ImageFormat format = ImageFormat.fromExtension(extensionOf(key)).orElseThrow(() -> {
            log.error("미디어 파일 형식 판별 실패: category={}, key={}", category, key);
            return new CustomException(ErrorCode.INTERNAL_SERVER_ERROR);
        });
        PutObjectRequest request = PutObjectRequest.builder()
            .bucket(properties.bucket())
            .key(objectKey(category, key))
            .contentType(format.contentType())
            .cacheControl(CACHE_CONTROL)
            .build();
        try {
            s3Client.putObject(request, RequestBody.fromBytes(content));
        } catch (SdkException exception) {
            log.error("미디어 파일 저장 실패: category={}, key={}", category, key, exception);
            throw new CustomException(ErrorCode.INTERNAL_SERVER_ERROR, exception);
        }
    }

    @Override
    public void delete(MediaCategory category, String key) {
        DeleteObjectRequest request = DeleteObjectRequest.builder()
            .bucket(properties.bucket())
            .key(objectKey(category, key))
            .build();
        try {
            s3Client.deleteObject(request);
        } catch (SdkException exception) {
            log.warn("미디어 파일 정리 실패: category={}, key={}", category, key, exception);
        }
    }

    @Override
    public String publicPath(MediaCategory category, String key) {
        return PATH_SEPARATOR + category.domainName() + PATH_SEPARATOR + category.directoryName()
            + PATH_SEPARATOR + key;
    }

    private String objectKey(MediaCategory category, String key) {
        return properties.keyPrefix() + category.domainName() + PATH_SEPARATOR + category.directoryName()
            + PATH_SEPARATOR + key;
    }

    // 확장자가 없으면 빈 문자열이라 어떤 형식과도 일치하지 않는다
    private String extensionOf(String key) {
        int separatorIndex = key.lastIndexOf(EXTENSION_SEPARATOR);
        return separatorIndex < 0 ? "" : key.substring(separatorIndex + 1);
    }

}
