package kr.co.teeq.api.admin.support;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

/**
 * admin 슬라이스 테스트 공통 빈. auth 체인을 import하지 않고도 관리자 체인이 뜨도록 필요한 빈만 둔다.
 */
@TestConfiguration(proxyBeanMethods = false)
public class AdminSliceTestConfig {

    public static final Instant NOW = Instant.parse("2026-10-20T03:00:00Z");

    @Bean
    PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    Clock clock() {
        return Clock.fixed(NOW, ZoneOffset.UTC);
    }

    @Bean
    ZoneId koreaZoneId() {
        return ZoneId.of("Asia/Seoul");
    }

}
