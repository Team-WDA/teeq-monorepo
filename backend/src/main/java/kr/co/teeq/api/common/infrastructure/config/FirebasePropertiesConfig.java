package kr.co.teeq.api.common.infrastructure.config;

import kr.co.teeq.api.common.infrastructure.properties.FirebaseProperties;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@EnableConfigurationProperties(FirebaseProperties.class)
public class FirebasePropertiesConfig {

}
