package kr.co.teeq.api.media.infrastructure.config;

import java.time.Duration;
import kr.co.teeq.api.media.infrastructure.properties.S3MediaProperties;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.core.client.config.ClientOverrideConfiguration;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;

/**
 * S3 클라이언트 설정. 자격 증명은 코드나 설정 파일에 두지 않고 SDK의 기본 자격 증명 체인(EC2 role 등)에 맡긴다.
 */
@Configuration
@EnableConfigurationProperties(S3MediaProperties.class)
public class S3MediaConfig {

    // 업로드는 최대 5MB라 한 번 시도가 수 초를 넘기지 않는다. 요청 스레드를 오래 붙잡지 않도록 시도별·전체 상한을 둔다
    private static final Duration API_CALL_ATTEMPT_TIMEOUT = Duration.ofSeconds(5);
    private static final Duration API_CALL_TIMEOUT = Duration.ofSeconds(15);

    @Bean
    public S3Client s3Client(S3MediaProperties properties) {
        return S3Client.builder()
            .region(Region.of(properties.region()))
            .overrideConfiguration(ClientOverrideConfiguration.builder()
                .apiCallAttemptTimeout(API_CALL_ATTEMPT_TIMEOUT)
                .apiCallTimeout(API_CALL_TIMEOUT)
                .build())
            .build();
    }

}
