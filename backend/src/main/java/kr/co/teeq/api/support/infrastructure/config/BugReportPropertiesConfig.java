package kr.co.teeq.api.support.infrastructure.config;

import kr.co.teeq.api.support.infrastructure.properties.BugReportProperties;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@EnableConfigurationProperties(BugReportProperties.class)
public class BugReportPropertiesConfig {

}
