package kr.co.teeq.api.media.infrastructure.properties;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * 미디어를 저장하는 S3 설정. 한 버킷을 환경(dev, prod)이 함께 쓰므로 {@code keyPrefix}로 환경을 구분한다.
 * {@code keyPrefix}는 앞의 슬래시를 제거하고 끝에 슬래시를 보장해 저장한다.
 */
@ConfigurationProperties(prefix = "media.s3")
public record S3MediaProperties(String bucket, String region, String keyPrefix) {

    private static final String PATH_SEPARATOR = "/";

    public S3MediaProperties {
        if (bucket == null || bucket.isBlank()) {
            throw new IllegalStateException("media.s3.bucket이 비어 있습니다");
        }
        if (region == null || region.isBlank()) {
            throw new IllegalStateException("media.s3.region이 비어 있습니다");
        }
        keyPrefix = normalizeKeyPrefix(keyPrefix);
    }

    private static String normalizeKeyPrefix(String keyPrefix) {
        String trimmed = keyPrefix == null ? "" : keyPrefix.strip();
        String withoutLeadingSeparator = trimmed.replaceFirst("^/+", "");
        if (withoutLeadingSeparator.isEmpty()) {
            throw new IllegalStateException("media.s3.key-prefix가 비어 있습니다");
        }
        return withoutLeadingSeparator.endsWith(PATH_SEPARATOR)
            ? withoutLeadingSeparator
            : withoutLeadingSeparator + PATH_SEPARATOR;
    }

}
