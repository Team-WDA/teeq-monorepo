package kr.co.teeq.api.media.infrastructure.properties;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;

class S3MediaPropertiesTest {

    private static final String BUCKET = "teeq-s3-bucket";
    private static final String REGION = "ap-northeast-2";
    private static final String KEY_PREFIX = "prod/";

    @Test
    void 정상_값이면_생성된다() {
        S3MediaProperties properties = new S3MediaProperties(BUCKET, REGION, KEY_PREFIX);

        assertThat(properties.bucket()).isEqualTo(BUCKET);
        assertThat(properties.region()).isEqualTo(REGION);
        assertThat(properties.keyPrefix()).isEqualTo("prod/");
    }

    @Test
    void keyPrefix는_끝에_슬래시가_보장된다() {
        S3MediaProperties properties = new S3MediaProperties(BUCKET, REGION, "prod");

        assertThat(properties.keyPrefix()).isEqualTo("prod/");
    }

    @Test
    void keyPrefix_앞의_슬래시는_제거된다() {
        S3MediaProperties properties = new S3MediaProperties(BUCKET, REGION, "/prod/");

        assertThat(properties.keyPrefix()).isEqualTo("prod/");
    }

    @Test
    void bucket이_null이거나_공백이면_예외() {
        assertThatThrownBy(() -> new S3MediaProperties(null, REGION, KEY_PREFIX))
            .isInstanceOf(IllegalStateException.class);
        assertThatThrownBy(() -> new S3MediaProperties(" ", REGION, KEY_PREFIX))
            .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void region이_null이거나_공백이면_예외() {
        assertThatThrownBy(() -> new S3MediaProperties(BUCKET, null, KEY_PREFIX))
            .isInstanceOf(IllegalStateException.class);
        assertThatThrownBy(() -> new S3MediaProperties(BUCKET, "", KEY_PREFIX))
            .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void keyPrefix가_null_공백_슬래시뿐이면_예외() {
        assertThatThrownBy(() -> new S3MediaProperties(BUCKET, REGION, null))
            .isInstanceOf(IllegalStateException.class);
        assertThatThrownBy(() -> new S3MediaProperties(BUCKET, REGION, " "))
            .isInstanceOf(IllegalStateException.class);
        assertThatThrownBy(() -> new S3MediaProperties(BUCKET, REGION, "/"))
            .isInstanceOf(IllegalStateException.class);
    }

}
