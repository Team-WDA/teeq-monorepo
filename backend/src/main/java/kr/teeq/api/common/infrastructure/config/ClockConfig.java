package kr.teeq.api.common.infrastructure.config;

import java.time.Clock;
import java.time.ZoneId;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class ClockConfig {

    /**
     * 서버 시각은 UTC로 통일한다. 현재 시각이 필요하면 이 Clock을 주입해서 사용한다.
     */
    @Bean
    public Clock clock() {
        return Clock.systemUTC();
    }

    /**
     * 야간 판정처럼 한국 시간 기준 규칙에만 사용한다.
     */
    @Bean
    public ZoneId koreaZoneId() {
        return ZoneId.of("Asia/Seoul");
    }

}
