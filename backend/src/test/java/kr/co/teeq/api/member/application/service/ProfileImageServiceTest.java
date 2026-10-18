package kr.co.teeq.api.member.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

import java.util.UUID;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.port.ProfileImageStoragePort;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InOrder;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;

@ExtendWith(MockitoExtension.class)
class ProfileImageServiceTest {

    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final byte[] PNG = {(byte) 0x89, 'P', 'N', 'G', '\r', '\n', 0x1A, '\n', 0, 0};

    @Mock
    private ProfileImageStoragePort profileImageStoragePort;

    @Mock
    private ProfileImageCommandService profileImageCommandService;

    private ProfileImageService profileImageService;

    @BeforeEach
    void setUp() {
        profileImageService = new ProfileImageService(profileImageStoragePort, profileImageCommandService);
    }

    private MockMultipartFile image(byte[] content) {
        return new MockMultipartFile("image", "photo.exe", "application/octet-stream", content);
    }

    private void assertFailsWith(byte[] content, ErrorCode expected) {
        assertThatThrownBy(() -> profileImageService.replace(MEMBER_ID, image(content)))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(expected));
        verifyNoInteractions(profileImageStoragePort, profileImageCommandService);
    }

    @Test
    void replace_emptyFile_throwsInvalid() {
        assertFailsWith(new byte[0], ErrorCode.PROFILE_IMAGE_INVALID);
    }

    @Test
    void replace_unsupportedFormat_throwsInvalid() {
        assertFailsWith("not an image".getBytes(), ErrorCode.PROFILE_IMAGE_INVALID);
    }

    @Test
    void replace_overFiveMegabytes_throwsTooLarge() {
        assertFailsWith(new byte[5 * 1024 * 1024 + 1], ErrorCode.PROFILE_IMAGE_TOO_LARGE);
    }

    @Test
    void replace_success_storesFileBeforeSavingRowWithDetectedFormat() {
        profileImageService.replace(MEMBER_ID, image(PNG));

        ArgumentCaptor<String> keyCaptor = ArgumentCaptor.forClass(String.class);
        InOrder order = inOrder(profileImageStoragePort, profileImageCommandService);
        order.verify(profileImageStoragePort).store(keyCaptor.capture(), eq(PNG));
        order.verify(profileImageCommandService)
            .replace(MEMBER_ID, keyCaptor.getValue(), "image/png", PNG.length);
        assertThat(keyCaptor.getValue()).endsWith(".png");
        verify(profileImageStoragePort, never()).delete(anyString());
    }

    @Test
    void replace_databaseFailure_deletesStoredFileAndRethrows() {
        IllegalStateException failure = new IllegalStateException("db down");
        doThrow(failure).when(profileImageCommandService).replace(any(), anyString(), anyString(), anyLong());

        assertThatThrownBy(() -> profileImageService.replace(MEMBER_ID, image(PNG))).isSameAs(failure);

        ArgumentCaptor<String> storedKey = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<String> deletedKey = ArgumentCaptor.forClass(String.class);
        verify(profileImageStoragePort).store(storedKey.capture(), any());
        verify(profileImageStoragePort).delete(deletedKey.capture());
        assertThat(deletedKey.getValue()).isEqualTo(storedKey.getValue());
    }

    @Test
    void replace_storageFailure_doesNotTouchDatabase() {
        CustomException failure = new CustomException(ErrorCode.INTERNAL_SERVER_ERROR);
        doThrow(failure).when(profileImageStoragePort).store(anyString(), any());

        assertThatThrownBy(() -> profileImageService.replace(MEMBER_ID, image(PNG))).isSameAs(failure);

        verifyNoInteractions(profileImageCommandService);
    }

    @Test
    void delete_delegatesToCommandServiceWithoutTouchingFiles() {
        profileImageService.delete(MEMBER_ID);

        verify(profileImageCommandService).delete(MEMBER_ID);
        verifyNoInteractions(profileImageStoragePort);
    }

}
