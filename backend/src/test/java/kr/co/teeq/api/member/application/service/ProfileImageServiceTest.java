package kr.co.teeq.api.member.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

import java.util.UUID;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.media.application.service.MediaService;
import kr.co.teeq.api.media.core.constant.MediaCategory;
import kr.co.teeq.api.media.core.model.StoredMedia;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InOrder;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;

@ExtendWith(MockitoExtension.class)
class ProfileImageServiceTest {

    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final StoredMedia STORED = new StoredMedia("stored-key.png", "image/png", 10L);

    @Mock
    private MediaService mediaService;

    @Mock
    private ProfileImageCommandService profileImageCommandService;

    private ProfileImageService profileImageService;

    private final MockMultipartFile image = new MockMultipartFile("image", "photo.png", "image/png", new byte[10]);

    @BeforeEach
    void setUp() {
        profileImageService = new ProfileImageService(mediaService, profileImageCommandService);
    }

    @Test
    void replace_success_passesStoredValuesToCommandService() {
        given(mediaService.storeImage(MediaCategory.PROFILE_IMAGE, image)).willReturn(STORED);

        profileImageService.replace(MEMBER_ID, image);

        InOrder order = inOrder(mediaService, profileImageCommandService);
        order.verify(mediaService).storeImage(MediaCategory.PROFILE_IMAGE, image);
        order.verify(profileImageCommandService).replace(MEMBER_ID, "stored-key.png", "image/png", 10L);
        verify(mediaService, never()).delete(any(), anyString());
    }

    @Test
    void replace_commandFails_deletesStoredFileAndRethrows() {
        given(mediaService.storeImage(MediaCategory.PROFILE_IMAGE, image)).willReturn(STORED);
        IllegalStateException failure = new IllegalStateException("db down");
        doThrow(failure).when(profileImageCommandService).replace(any(), anyString(), anyString(), anyLong());

        assertThatThrownBy(() -> profileImageService.replace(MEMBER_ID, image)).isSameAs(failure);

        verify(mediaService).delete(MediaCategory.PROFILE_IMAGE, "stored-key.png");
    }

    @Test
    void replace_storeRejected_doesNotTouchDatabase() {
        CustomException failure = new CustomException(ErrorCode.PROFILE_IMAGE_INVALID);
        given(mediaService.storeImage(MediaCategory.PROFILE_IMAGE, image)).willThrow(failure);

        assertThatThrownBy(() -> profileImageService.replace(MEMBER_ID, image))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.PROFILE_IMAGE_INVALID));

        verifyNoInteractions(profileImageCommandService);
        verify(mediaService, never()).delete(any(), anyString());
    }

    @Test
    void delete_delegatesToCommandServiceWithoutTouchingFiles() {
        profileImageService.delete(MEMBER_ID);

        verify(profileImageCommandService).delete(MEMBER_ID);
        verifyNoInteractions(mediaService);
    }

}
