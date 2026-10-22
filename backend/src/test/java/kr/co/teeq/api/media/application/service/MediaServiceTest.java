package kr.co.teeq.api.media.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.catchThrowable;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import java.io.IOException;
import java.util.List;
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
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.multipart.MultipartFile;

@ExtendWith(MockitoExtension.class)
class MediaServiceTest {

    private static final byte[] JPEG_CONTENT = {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF, 0x00, 0x01};
    private static final byte[] PNG_CONTENT = {(byte) 0x89, 'P', 'N', 'G', '\r', '\n', 0x1A, '\n', 0, 0};
    private static final byte[] TEXT_CONTENT = {'h', 'e', 'l', 'l', 'o'};

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

    private MultipartFile imageFile(byte[] content) {
        return new MockMultipartFile("images", "image", "application/octet-stream", content);
    }

    private byte[] pngPaddedTo(int sizeBytes) {
        byte[] content = new byte[sizeBytes];
        System.arraycopy(PNG_CONTENT, 0, content, 0, PNG_CONTENT.length);
        return content;
    }

    private CustomException expectCustomException(List<MultipartFile> files) {
        Throwable thrown = catchThrowable(
            () -> mediaService.storeImages(MediaCategory.BUG_REPORT_IMAGE, files));
        assertThat(thrown).isInstanceOf(CustomException.class);
        return (CustomException) thrown;
    }

    @Test
    void storeImages_validatesAllBeforeStoring() {
        List<MultipartFile> files = List.of(imageFile(PNG_CONTENT), imageFile(JPEG_CONTENT), imageFile(TEXT_CONTENT));

        assertThat(expectCustomException(files).getErrorCode()).isEqualTo(ErrorCode.BUG_REPORT_IMAGE_INVALID);
        verifyNoInteractions(mediaStoragePort);
    }

    @Test
    void storeImages_tooLargeFile_throwsTooLarge() {
        int limit = (int) MediaCategory.BUG_REPORT_IMAGE.maximumSizeBytes();
        List<MultipartFile> files = List.of(imageFile(pngPaddedTo(limit + 1)));

        assertThat(expectCustomException(files).getErrorCode()).isEqualTo(ErrorCode.BUG_REPORT_IMAGE_TOO_LARGE);
        verifyNoInteractions(mediaStoragePort);
    }

    @Test
    void storeImages_exactlyMaximumSize_isAccepted() {
        int limit = (int) MediaCategory.BUG_REPORT_IMAGE.maximumSizeBytes();

        List<StoredMedia> stored = mediaService.storeImages(MediaCategory.BUG_REPORT_IMAGE,
            List.of(imageFile(pngPaddedTo(limit))));

        assertThat(stored).hasSize(1);
        assertThat(stored.get(0).sizeBytes()).isEqualTo(limit);
    }

    @Test
    void storeImages_emptyFile_throwsInvalidWithoutStoring() {
        List<MultipartFile> files = List.of(imageFile(PNG_CONTENT), imageFile(new byte[0]));

        assertThat(expectCustomException(files).getErrorCode()).isEqualTo(ErrorCode.BUG_REPORT_IMAGE_INVALID);
        verifyNoInteractions(mediaStoragePort);
    }

    @Test
    void storeImages_emptyList_returnsEmptyList() {
        assertThat(mediaService.storeImages(MediaCategory.BUG_REPORT_IMAGE, List.of())).isEmpty();
        verifyNoInteractions(mediaStoragePort);
    }

    @Test
    void storeImages_storeFailure_deletesAlreadyStored() {
        CustomException failure = new CustomException(ErrorCode.BUG_REPORT_IMAGE_INVALID);
        ArgumentCaptor<String> storedKeys = ArgumentCaptor.forClass(String.class);
        doNothing().doThrow(failure).when(mediaStoragePort)
            .store(eq(MediaCategory.BUG_REPORT_IMAGE), storedKeys.capture(), any());
        List<MultipartFile> files = List.of(imageFile(PNG_CONTENT), imageFile(JPEG_CONTENT));

        assertThatThrownBy(() -> mediaService.storeImages(MediaCategory.BUG_REPORT_IMAGE, files)).isSameAs(failure);

        String firstKey = storedKeys.getAllValues().get(0);
        String failedKey = storedKeys.getAllValues().get(1);
        verify(mediaStoragePort, times(1)).delete(MediaCategory.BUG_REPORT_IMAGE, firstKey);
        verify(mediaStoragePort, never()).delete(MediaCategory.BUG_REPORT_IMAGE, failedKey);
    }

    @Test
    void storeImages_returnsKeysInInputOrder() {
        List<StoredMedia> stored = mediaService.storeImages(MediaCategory.BUG_REPORT_IMAGE,
            List.of(imageFile(PNG_CONTENT), imageFile(JPEG_CONTENT)));

        assertThat(stored).extracting(StoredMedia::contentType).containsExactly("image/png", "image/jpeg");
        assertThat(stored.get(0).key()).endsWith(".png");
        assertThat(stored.get(1).key()).endsWith(".jpg");
    }

    @Test
    void deleteAll_deletesEveryKey() {
        mediaService.deleteAll(MediaCategory.BUG_REPORT_IMAGE, List.of("a.png", "b.jpg"));

        verify(mediaStoragePort).delete(MediaCategory.BUG_REPORT_IMAGE, "a.png");
        verify(mediaStoragePort).delete(MediaCategory.BUG_REPORT_IMAGE, "b.jpg");
    }

}
