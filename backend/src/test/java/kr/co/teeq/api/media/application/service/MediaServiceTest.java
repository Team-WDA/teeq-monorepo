package kr.co.teeq.api.media.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import java.io.IOException;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.media.core.constant.MediaCategory;
import kr.co.teeq.api.media.core.model.StoredMedia;
import kr.co.teeq.api.media.core.port.MediaStoragePort;
import kr.co.teeq.api.setting.application.service.SettingConfigService;
import kr.co.teeq.api.setting.core.constant.SettingKey;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.multipart.MultipartFile;

@ExtendWith(MockitoExtension.class)
class MediaServiceTest {

    private static final byte[] JPEG_CONTENT = {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF, 0x00, 0x01};

    @Mock
    private MediaStoragePort mediaStoragePort;
    @Mock
    private SettingConfigService settingConfigService;

    private MediaService mediaService;

    @BeforeEach
    void setUp() {
        mediaService = new MediaService(mediaStoragePort, settingConfigService);
    }

    @Test
    void storeImage_validJpeg_storesAndReturnsKeyWithExtension() {
        MultipartFile file = new MockMultipartFile("image", "a.png", "image/png", JPEG_CONTENT);

        StoredMedia stored = mediaService.storeImage(MediaCategory.PROFILE_IMAGE, file);

        assertThat(stored.key()).matches("[0-9a-f-]{36}\\.jpg");
        assertThat(stored.contentType()).isEqualTo("image/jpeg");
        assertThat(stored.sizeBytes()).isEqualTo(JPEG_CONTENT.length);
        verify(mediaStoragePort).store(MediaCategory.PROFILE_IMAGE, stored.key(), JPEG_CONTENT);
    }

    @Test
    void storeImage_overLimit_throwsTooLargeWithoutReadingContent() throws IOException {
        MultipartFile file = mock(MultipartFile.class);
        when(file.getSize()).thenReturn(MediaCategory.PROFILE_IMAGE.maximumSizeBytes() + 1);

        assertThatThrownBy(() -> mediaService.storeImage(MediaCategory.PROFILE_IMAGE, file))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.PROFILE_IMAGE_TOO_LARGE));

        verify(file, never()).getBytes();
        verifyNoInteractions(mediaStoragePort);
    }

    @Test
    void storeImage_empty_throwsInvalid() {
        MultipartFile file = new MockMultipartFile("image", new byte[0]);

        assertThatThrownBy(() -> mediaService.storeImage(MediaCategory.PROFILE_IMAGE, file))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.PROFILE_IMAGE_INVALID));
        verifyNoInteractions(mediaStoragePort);
    }

    @Test
    void storeImage_unreadable_throwsInvalidWithCause() throws IOException {
        IOException cause = new IOException("읽기 실패");
        MultipartFile file = mock(MultipartFile.class);
        when(file.getSize()).thenReturn(10L);
        when(file.isEmpty()).thenReturn(false);
        when(file.getBytes()).thenThrow(cause);

        assertThatThrownBy(() -> mediaService.storeImage(MediaCategory.PROFILE_IMAGE, file))
            .isInstanceOfSatisfying(CustomException.class, exception -> {
                assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.PROFILE_IMAGE_INVALID);
                assertThat(exception.getCause()).isSameAs(cause);
            });
        verifyNoInteractions(mediaStoragePort);
    }

    @Test
    void storeImage_notAnImage_throwsInvalid() {
        MultipartFile file = new MockMultipartFile("image", "a.jpg", "image/jpeg", "text".getBytes());

        assertThatThrownBy(() -> mediaService.storeImage(MediaCategory.PROFILE_IMAGE, file))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.PROFILE_IMAGE_INVALID));
        verifyNoInteractions(mediaStoragePort);
    }

    @Test
    void storeImage_storeFails_propagates() {
        MultipartFile file = new MockMultipartFile("image", JPEG_CONTENT);
        IllegalStateException failure = new IllegalStateException("저장 실패");
        doThrow(failure).when(mediaStoragePort).store(eq(MediaCategory.PROFILE_IMAGE), any(), eq(JPEG_CONTENT));

        assertThatThrownBy(() -> mediaService.storeImage(MediaCategory.PROFILE_IMAGE, file)).isSameAs(failure);
    }

    @Test
    void urlFor_baseWithTrailingSlash_noDoubleSlash() {
        when(settingConfigService.getString(SettingKey.MEDIA_BASE_URL)).thenReturn("https://x.kr/");
        when(mediaStoragePort.publicPath(MediaCategory.PROFILE_IMAGE, "k.jpg"))
            .thenReturn("/media/profile-images/k.jpg");

        assertThat(mediaService.urlFor(MediaCategory.PROFILE_IMAGE, "k.jpg"))
            .isEqualTo("https://x.kr/media/profile-images/k.jpg");
    }

    @Test
    void urlFor_baseWithoutSlash_joinsOnce() {
        when(settingConfigService.getString(SettingKey.MEDIA_BASE_URL)).thenReturn("https://x.kr");
        when(mediaStoragePort.publicPath(MediaCategory.PROFILE_IMAGE, "k.jpg"))
            .thenReturn("/media/profile-images/k.jpg");

        assertThat(mediaService.urlFor(MediaCategory.PROFILE_IMAGE, "k.jpg"))
            .isEqualTo("https://x.kr/media/profile-images/k.jpg");
    }

    @Test
    void delete_delegatesToPort() {
        mediaService.delete(MediaCategory.PROFILE_IMAGE, "k.jpg");

        verify(mediaStoragePort).delete(MediaCategory.PROFILE_IMAGE, "k.jpg");
    }

}
