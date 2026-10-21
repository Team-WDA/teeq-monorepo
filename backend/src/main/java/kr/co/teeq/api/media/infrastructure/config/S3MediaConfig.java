package kr.co.teeq.api.media.infrastructure.config;

import kr.co.teeq.api.media.infrastructure.properties.S3MediaProperties;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;

/**
 * S3 클라이언트 설정. 자격 증명은 코드나 설정 파일에 두지 않고 SDK의 기본 자격 증명 체인(EC2 role 등)에 맡긴다.
 */
@Configuration
@EnableConfigurationProperties(S3MediaProperties.class)
public class S3MediaConfig {

    @Bean
    public S3Client s3Client(S3MediaProperties properties) {
        return S3Client.builder()
            .region(Region.of(properties.region()))
            .build();
    }

}
