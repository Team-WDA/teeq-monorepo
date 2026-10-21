package kr.co.teeq.api.media.infrastructure.config;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Duration;
import kr.co.teeq.api.media.core.port.MediaStoragePort;
import kr.co.teeq.api.media.infrastructure.adapter.S3MediaStorage;
import kr.co.teeq.api.media.infrastructure.adapter.VolumeMediaStorage;
import kr.co.teeq.api.media.infrastructure.properties.S3MediaProperties;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;
import software.amazon.awssdk.core.client.config.ClientOverrideConfiguration;
import software.amazon.awssdk.services.s3.S3Client;

class S3MediaConfigTest {

    private final ApplicationContextRunner contextRunner = new ApplicationContextRunner()
        .withUserConfiguration(S3MediaConfig.class, S3MediaStorage.class, VolumeMediaStorage.class)
        .withPropertyValues(
            "media.s3.bucket=teeq-s3-bucket",
            "media.s3.region=ap-northeast-2",
            "media.s3.key-prefix=dev/");

    @Test
    void 저장소가_둘이어도_S3MediaStorage가_선택된다() {
        contextRunner.run(context -> {
            assertThat(context.getBeansOfType(MediaStoragePort.class)).hasSize(2);
            assertThat(context.getBean(MediaStoragePort.class)).isInstanceOf(S3MediaStorage.class);
        });
    }

    @Test
    void 설정_키가_프로퍼티와_S3Client로_바인딩된다() {
        contextRunner.run(context -> {
            S3MediaProperties properties = context.getBean(S3MediaProperties.class);
            assertThat(properties.bucket()).isEqualTo("teeq-s3-bucket");
            assertThat(properties.region()).isEqualTo("ap-northeast-2");
            assertThat(properties.keyPrefix()).isEqualTo("dev/");
            assertThat(context.getBean(S3Client.class).serviceClientConfiguration().region().id())
                .isEqualTo("ap-northeast-2");
        });
    }

    @Test
    void S3Client에는_호출_전체와_시도별_타임아웃이_설정된다() {
        contextRunner.run(context -> {
            ClientOverrideConfiguration override = context.getBean(S3Client.class)
                .serviceClientConfiguration().overrideConfiguration();
            assertThat(override.apiCallTimeout()).contains(Duration.ofSeconds(15));
            assertThat(override.apiCallAttemptTimeout()).contains(Duration.ofSeconds(5));
        });
    }

    @Test
    void key_prefix가_비어_있으면_기동에_실패한다() {
        contextRunner.withPropertyValues("media.s3.key-prefix=").run(context ->
            assertThat(context).hasFailed());
    }

}
