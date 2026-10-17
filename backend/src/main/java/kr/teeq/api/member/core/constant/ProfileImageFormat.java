package kr.teeq.api.member.core.constant;

import java.util.Arrays;
import java.util.Optional;

/**
 * 프로필 사진으로 허용하는 이미지 형식. 클라이언트가 보낸 파일명과 content type은 믿지 않고 파일 앞부분(매직 바이트)으로 판별한다.
 */
public enum ProfileImageFormat {

    JPEG("image/jpeg", "jpg"),
    PNG("image/png", "png"),
    WEBP("image/webp", "webp");

    private static final byte[] JPEG_SIGNATURE = {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF};
    private static final byte[] PNG_SIGNATURE = {(byte) 0x89, 'P', 'N', 'G', '\r', '\n', 0x1A, '\n'};
    private static final byte[] RIFF_SIGNATURE = {'R', 'I', 'F', 'F'};
    private static final byte[] WEBP_SIGNATURE = {'W', 'E', 'B', 'P'};
    private static final int WEBP_SIGNATURE_OFFSET = 8;

    private final String contentType;
    private final String extension;

    ProfileImageFormat(String contentType, String extension) {
        this.contentType = contentType;
        this.extension = extension;
    }

    public String contentType() {
        return contentType;
    }

    public String extension() {
        return extension;
    }

    public static Optional<ProfileImageFormat> detect(byte[] content) {
        return Arrays.stream(values())
            .filter(format -> format.matches(content))
            .findFirst();
    }

    private boolean matches(byte[] content) {
        return switch (this) {
            case JPEG -> startsWith(content, 0, JPEG_SIGNATURE);
            case PNG -> startsWith(content, 0, PNG_SIGNATURE);
            case WEBP -> startsWith(content, 0, RIFF_SIGNATURE)
                && startsWith(content, WEBP_SIGNATURE_OFFSET, WEBP_SIGNATURE);
        };
    }

    private static boolean startsWith(byte[] content, int offset, byte[] signature) {
        if (content.length < offset + signature.length) {
            return false;
        }
        return Arrays.equals(content, offset, offset + signature.length, signature, 0, signature.length);
    }

}
