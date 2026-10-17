package kr.co.teeq.api.common.infrastructure.properties;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;

class AiServerPropertiesTest {

    private static final String BASE_URL = "http://localhost:9000";
    private static final String HEADER_NAME = "X-Test-Header";
    private static final String HEADER_VALUE = "dummy-value";

    @Test
    void 정상_값이면_생성된다() {
        AiServerProperties properties = new AiServerProperties(BASE_URL, HEADER_NAME, HEADER_VALUE, 3000L);

        assertThat(properties.baseUrl()).isEqualTo(BASE_URL);
        assertThat(properties.authHeaderName()).isEqualTo(HEADER_NAME);
        assertThat(properties.authHeaderValue()).isEqualTo(HEADER_VALUE);
        assertThat(properties.timeoutMillis()).isEqualTo(3000L);
    }

    @Test
    void baseUrl이_null이거나_공백이면_예외() {
        assertThatThrownBy(() -> new AiServerProperties(null, HEADER_NAME, HEADER_VALUE, 3000L))
            .isInstanceOf(IllegalStateException.class);
        assertThatThrownBy(() -> new AiServerProperties(" ", HEADER_NAME, HEADER_VALUE, 3000L))
            .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void authHeaderName이_null이거나_공백이면_예외() {
        assertThatThrownBy(() -> new AiServerProperties(BASE_URL, null, HEADER_VALUE, 3000L))
            .isInstanceOf(IllegalStateException.class);
        assertThatThrownBy(() -> new AiServerProperties(BASE_URL, "", HEADER_VALUE, 3000L))
            .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void authHeaderValue가_null이거나_공백이면_예외() {
        assertThatThrownBy(() -> new AiServerProperties(BASE_URL, HEADER_NAME, null, 3000L))
            .isInstanceOf(IllegalStateException.class);
        assertThatThrownBy(() -> new AiServerProperties(BASE_URL, HEADER_NAME, "  ", 3000L))
            .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void timeoutMillis가_0이하이면_예외() {
        assertThatThrownBy(() -> new AiServerProperties(BASE_URL, HEADER_NAME, HEADER_VALUE, 0L))
            .isInstanceOf(IllegalStateException.class);
        assertThatThrownBy(() -> new AiServerProperties(BASE_URL, HEADER_NAME, HEADER_VALUE, -1L))
            .isInstanceOf(IllegalStateException.class);
    }

}
