package kr.co.teeq.api.admin.infrastructure.config;

import kr.co.teeq.api.admin.infrastructure.properties.AdminAccountProperties;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@EnableConfigurationProperties(AdminAccountProperties.class)
public class AdminAccountPropertiesConfig {

}
