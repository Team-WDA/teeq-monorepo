package kr.teeq.api.common.core.entity;

import static org.assertj.core.api.Assertions.assertThat;

import kr.teeq.api.TestcontainersConfiguration;
import kr.teeq.api.common.infrastructure.config.JpaAuditingConfig;
import kr.teeq.testsupport.SampleEntity;
import jakarta.persistence.EntityManager;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;
import org.springframework.boot.jdbc.test.autoconfigure.AutoConfigureTestDatabase;
import org.springframework.boot.persistence.autoconfigure.EntityScan;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;

@DataJpaTest(properties = {
    "spring.flyway.enabled=false",
    "spring.jpa.hibernate.ddl-auto=create-drop"
})
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Import({TestcontainersConfiguration.class, JpaAuditingConfig.class})
class BaseEntityIntegrationTest {

    private static final Instant FIXED_INSTANT = Instant.parse("2026-09-21T01:02:03Z");

    @Autowired
    private EntityManager entityManager;

    @Test
    void persist_generatesVersion7UuidAndAuditTimestampsFromClock() {
        SampleEntity sample = new SampleEntity();

        entityManager.persist(sample);
        entityManager.flush();

        assertThat(sample.getId()).isNotNull();
        assertThat(sample.getId().version()).isEqualTo(7);
        assertThat(sample.getCreatedAt()).isEqualTo(FIXED_INSTANT);
        assertThat(sample.getUpdatedAt()).isEqualTo(FIXED_INSTANT);
    }

    @TestConfiguration(proxyBeanMethods = false)
    @EntityScan(basePackageClasses = SampleEntity.class)
    static class SampleEntityConfig {

        @Bean
        Clock clock() {
            return Clock.fixed(FIXED_INSTANT, ZoneOffset.UTC);
        }

    }

}
