package kr.teeq.api.member.core.constant;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.Optional;
import org.junit.jupiter.api.Test;

class ProfileImageFormatTest {

    private static final byte[] JPEG = {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF, (byte) 0xE0, 0, 0x10};
    private static final byte[] PNG = {(byte) 0x89, 'P', 'N', 'G', '\r', '\n', 0x1A, '\n', 0, 0};
    private static final byte[] WEBP = {'R', 'I', 'F', 'F', 1, 2, 3, 4, 'W', 'E', 'B', 'P', 'V', 'P', '8', ' '};

    @Test
    void detect_recognizesEachSupportedFormat() {
        assertThat(ProfileImageFormat.detect(JPEG)).contains(ProfileImageFormat.JPEG);
        assertThat(ProfileImageFormat.detect(PNG)).contains(ProfileImageFormat.PNG);
        assertThat(ProfileImageFormat.detect(WEBP)).contains(ProfileImageFormat.WEBP);
    }

    @Test
    void detect_exposesContentTypeAndExtension() {
        assertThat(ProfileImageFormat.JPEG.contentType()).isEqualTo("image/jpeg");
        assertThat(ProfileImageFormat.JPEG.extension()).isEqualTo("jpg");
        assertThat(ProfileImageFormat.PNG.contentType()).isEqualTo("image/png");
        assertThat(ProfileImageFormat.WEBP.extension()).isEqualTo("webp");
    }

    @Test
    void detect_rejectsUnsupportedOrTruncatedContent() {
        assertThat(ProfileImageFormat.detect(new byte[0])).isEqualTo(Optional.empty());
        assertThat(ProfileImageFormat.detect(new byte[] {(byte) 0xFF, (byte) 0xD8})).isEmpty();
        assertThat(ProfileImageFormat.detect("GIF89a-not-allowed".getBytes())).isEmpty();
        assertThat(ProfileImageFormat.detect("<svg></svg>".getBytes())).isEmpty();
    }

    @Test
    void detect_rejectsRiffContainerThatIsNotWebp() {
        byte[] wave = {'R', 'I', 'F', 'F', 1, 2, 3, 4, 'W', 'A', 'V', 'E'};

        assertThat(ProfileImageFormat.detect(wave)).isEmpty();
    }

}
