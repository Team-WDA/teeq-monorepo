package kr.co.teeq.api.common.infrastructure.properties;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;

class FirebasePropertiesTest {

    @Test
    void 정상_값이면_생성된다() {
        FirebaseProperties properties = new FirebaseProperties("classpath:firebase-service-account.json");

        assertThat(properties.serviceAccountLocation()).isEqualTo("classpath:firebase-service-account.json");
    }

    @Test
    void 위치가_null이거나_공백이면_예외() {
        assertThatThrownBy(() -> new FirebaseProperties(null)).isInstanceOf(IllegalStateException.class);
        assertThatThrownBy(() -> new FirebaseProperties(" ")).isInstanceOf(IllegalStateException.class);
    }

}
