package kr.co.teeq.api.common.infrastructure.properties;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.Duration;
import org.junit.jupiter.api.Test;

class AiServerMetricsPropertiesTest {

    @Test
    void timeout이_null이면_기본_15초다() {
        assertThat(new AiServerMetricsProperties(null).timeout()).isEqualTo(Duration.ofSeconds(15));
    }

    @Test
    void 지정한_timeout을_그대로_쓴다() {
        assertThat(new AiServerMetricsProperties(Duration.ofSeconds(30)).timeout())
            .isEqualTo(Duration.ofSeconds(30));
    }

    @Test
    void timeout이_0이거나_음수이면_예외이고_메시지에_키_이름만_있다() {
        assertThatThrownBy(() -> new AiServerMetricsProperties(Duration.ZERO))
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining("ai-server.metrics.timeout");
        assertThatThrownBy(() -> new AiServerMetricsProperties(Duration.ofSeconds(-1)))
            .isInstanceOf(IllegalStateException.class)
            .hasMessageNotContaining("-1");
    }

}
