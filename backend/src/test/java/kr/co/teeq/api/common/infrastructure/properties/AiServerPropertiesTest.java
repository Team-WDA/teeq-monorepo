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
        AiServerProperties properties = new AiServerProperties(BASE_URL, HEADER_NAME, HEADER_VALUE);

        assertThat(properties.baseUrl()).isEqualTo(BASE_URL);
        assertThat(properties.authHeaderName()).isEqualTo(HEADER_NAME);
        assertThat(properties.authHeaderValue()).isEqualTo(HEADER_VALUE);
    }

    @Test
    void apiBaseUrl_호스트만_있으면_접두사를_붙인다() {
        AiServerProperties properties = new AiServerProperties("https://ai.example", HEADER_NAME, HEADER_VALUE);

        assertThat(properties.apiBaseUrl()).isEqualTo("https://ai.example/internal/v1");
    }

    @Test
    void apiBaseUrl_끝_슬래시를_중복하지_않는다() {
        AiServerProperties properties = new AiServerProperties("https://ai.example/", HEADER_NAME, HEADER_VALUE);

        assertThat(properties.apiBaseUrl()).isEqualTo("https://ai.example/internal/v1");
    }

    @Test
    void baseUrl이_null이거나_공백이면_예외() {
        assertThatThrownBy(() -> new AiServerProperties(null, HEADER_NAME, HEADER_VALUE))
            .isInstanceOf(IllegalStateException.class);
        assertThatThrownBy(() -> new AiServerProperties(" ", HEADER_NAME, HEADER_VALUE))
            .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void authHeaderName이_null이거나_공백이면_예외() {
        assertThatThrownBy(() -> new AiServerProperties(BASE_URL, null, HEADER_VALUE))
            .isInstanceOf(IllegalStateException.class);
        assertThatThrownBy(() -> new AiServerProperties(BASE_URL, "", HEADER_VALUE))
            .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void authHeaderValue가_null이거나_공백이면_예외() {
        assertThatThrownBy(() -> new AiServerProperties(BASE_URL, HEADER_NAME, null))
            .isInstanceOf(IllegalStateException.class);
        assertThatThrownBy(() -> new AiServerProperties(BASE_URL, HEADER_NAME, "  "))
            .isInstanceOf(IllegalStateException.class);
    }

}
