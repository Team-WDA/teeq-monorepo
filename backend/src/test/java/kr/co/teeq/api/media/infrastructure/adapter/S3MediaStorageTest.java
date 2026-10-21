package kr.co.teeq.api.media.infrastructure.adapter;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.io.IOException;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.media.core.constant.MediaCategory;
import kr.co.teeq.api.media.infrastructure.properties.S3MediaProperties;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.context.annotation.Primary;
import software.amazon.awssdk.core.exception.SdkClientException;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

class S3MediaStorageTest {

    private static final MediaCategory CATEGORY = MediaCategory.PROFILE_IMAGE;
    private static final String BUCKET = "teeq-s3-bucket";
    private static final String CACHE_CONTROL = "public, max-age=31536000, immutable";

    private S3Client s3Client;
    private S3MediaStorage storage;

    @BeforeEach
    void setUp() {
        s3Client = mock(S3Client.class);
        storage = new S3MediaStorage(s3Client, new S3MediaProperties(BUCKET, "ap-northeast-2", "prod/"));
    }

    @Test
    void store는_prefix_도메인_디렉터리_키로_PutObject한다() throws IOException {
        byte[] content = {1, 2, 3};

        storage.store(CATEGORY, "abc.jpg", content);

        ArgumentCaptor<PutObjectRequest> requestCaptor = ArgumentCaptor.forClass(PutObjectRequest.class);
        ArgumentCaptor<RequestBody> bodyCaptor = ArgumentCaptor.forClass(RequestBody.class);
        verify(s3Client).putObject(requestCaptor.capture(), bodyCaptor.capture());
        PutObjectRequest request = requestCaptor.getValue();
        assertThat(request.bucket()).isEqualTo(BUCKET);
        assertThat(request.key()).isEqualTo("prod/member/profile-images/abc.jpg");
        assertThat(request.contentType()).isEqualTo("image/jpeg");
        assertThat(request.cacheControl()).isEqualTo(CACHE_CONTROL);
        assertThat(bodyCaptor.getValue().contentStreamProvider().newStream().readAllBytes()).isEqualTo(content);
    }

    @Test
    void store는_확장자별_content_type을_쓴다() {
        storage.store(CATEGORY, "abc.png", new byte[] {1});
        storage.store(CATEGORY, "abc.webp", new byte[] {1});

        ArgumentCaptor<PutObjectRequest> requestCaptor = ArgumentCaptor.forClass(PutObjectRequest.class);
        verify(s3Client, times(2)).putObject(requestCaptor.capture(), any(RequestBody.class));
        assertThat(requestCaptor.getAllValues()).extracting(PutObjectRequest::contentType)
            .containsExactly("image/png", "image/webp");
    }

    @Test
    void store는_알_수_없는_확장자면_INTERNAL_SERVER_ERROR() {
        assertThatThrownBy(() -> storage.store(CATEGORY, "abc.gif", new byte[] {1}))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.INTERNAL_SERVER_ERROR));
        assertThatThrownBy(() -> storage.store(CATEGORY, "abc", new byte[] {1}))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.INTERNAL_SERVER_ERROR));

        verify(s3Client, never()).putObject(any(PutObjectRequest.class), any(RequestBody.class));
    }

    @Test
    void store는_S3_예외를_INTERNAL_SERVER_ERROR로_변환한다() {
        when(s3Client.putObject(any(PutObjectRequest.class), any(RequestBody.class)))
            .thenThrow(SdkClientException.create("연결 실패"));

        assertThatThrownBy(() -> storage.store(CATEGORY, "abc.jpg", new byte[] {1}))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.INTERNAL_SERVER_ERROR));
    }

    @Test
    void delete는_같은_키로_DeleteObject한다() {
        storage.delete(CATEGORY, "abc.jpg");

        ArgumentCaptor<DeleteObjectRequest> requestCaptor = ArgumentCaptor.forClass(DeleteObjectRequest.class);
        verify(s3Client).deleteObject(requestCaptor.capture());
        assertThat(requestCaptor.getValue().bucket()).isEqualTo(BUCKET);
        assertThat(requestCaptor.getValue().key()).isEqualTo("prod/member/profile-images/abc.jpg");
    }

    @Test
    void delete는_S3_예외를_전파하지_않는다() {
        when(s3Client.deleteObject(any(DeleteObjectRequest.class)))
            .thenThrow(SdkClientException.create("연결 실패"));

        assertThatCode(() -> storage.delete(CATEGORY, "abc.jpg")).doesNotThrowAnyException();
    }

    @Test
    void publicPath는_도메인과_디렉터리와_키로_계산한다() {
        assertThat(storage.publicPath(CATEGORY, "abc.jpg")).isEqualTo("/member/profile-images/abc.jpg");
    }

    @Test
    void S3MediaStorage에는_Primary가_선언되어_있다() {
        assertThat(S3MediaStorage.class.isAnnotationPresent(Primary.class)).isTrue();
    }

    @Test
    void PROFILE_IMAGE의_domainName은_member다() {
        assertThat(MediaCategory.PROFILE_IMAGE.domainName()).isEqualTo("member");
    }

}
