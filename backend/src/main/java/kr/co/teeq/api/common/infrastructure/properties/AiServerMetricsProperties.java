package kr.co.teeq.api.common.infrastructure.properties;

import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;

// AI 집계 호출 설정. 선택 값이며 비우면 15초다
@ConfigurationProperties(prefix = "ai-server.metrics")
public record AiServerMetricsProperties(Duration timeout) {

    private static final Duration DEFAULT_TIMEOUT = Duration.ofSeconds(15);

    public AiServerMetricsProperties {
        if (timeout == null) {
            timeout = DEFAULT_TIMEOUT;
        } else if (timeout.isZero() || timeout.isNegative()) {
            throw new IllegalStateException("ai-server.metrics.timeout은 0보다 커야 합니다");
        }
    }

}
