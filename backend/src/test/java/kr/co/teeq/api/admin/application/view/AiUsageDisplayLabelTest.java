package kr.co.teeq.api.admin.application.view;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class AiUsageDisplayLabelTest {

    @Test
    void kind_knownKinds_returnUpperCase() {
        assertThat(AiUsageDisplayLabel.kind("stt")).isEqualTo("STT");
        assertThat(AiUsageDisplayLabel.kind("llm")).isEqualTo("LLM");
        assertThat(AiUsageDisplayLabel.kind("tts")).isEqualTo("TTS");
    }

    @Test
    void kind_unknownKind_returnsUpperCase() {
        assertThat(AiUsageDisplayLabel.kind("custom")).isEqualTo("CUSTOM");
    }

    @Test
    void kind_null_returnsDash() {
        assertThat(AiUsageDisplayLabel.kind(null)).isEqualTo("-");
    }

}
