package kr.co.teeq.api.common.infrastructure.config;

import kr.co.teeq.api.common.infrastructure.properties.AiServerMetricsProperties;
import kr.co.teeq.api.common.infrastructure.properties.AiServerProperties;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@EnableConfigurationProperties({AiServerProperties.class, AiServerMetricsProperties.class})
public class AiServerPropertiesConfig {

}
