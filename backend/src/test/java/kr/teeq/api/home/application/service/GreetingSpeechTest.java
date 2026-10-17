package kr.teeq.api.home.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import kr.teeq.api.onboarding.core.constant.OnboardingOption;
import kr.teeq.api.setting.core.constant.SettingKey;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

class GreetingSpeechTest {

    @Test
    void from_반말_선택지는_CASUAL() {
        assertThat(GreetingSpeech.from(OnboardingOption.SPEECH_STYLE_CLOSE_FRIEND_CASUAL))
            .isEqualTo(GreetingSpeech.CASUAL);
        assertThat(GreetingSpeech.from(OnboardingOption.SPEECH_STYLE_AFFECTIONATE_CASUAL))
            .isEqualTo(GreetingSpeech.CASUAL);
    }

    @Test
    void from_존댓말_선택지는_POLITE() {
        assertThat(GreetingSpeech.from(OnboardingOption.SPEECH_STYLE_GENTLE_POLITE)).isEqualTo(GreetingSpeech.POLITE);
    }

    @Test
    void from_말투가_아닌_선택지는_IllegalArgumentException() {
        assertThatThrownBy(() -> GreetingSpeech.from(OnboardingOption.RELATIONSHIP_CLOSE_FRIEND))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @ParameterizedTest
    @CsvSource({"소연,소연아", "민지,민지야", "가,가야", "힣,힣아", "Mina,Mina", "민지1,민지1"})
    void honorific_CASUAL은_받침에_따라_아_야를_붙이고_한글이_아니면_그대로(String nickname, String expected) {
        assertThat(GreetingSpeech.CASUAL.honorific(nickname)).isEqualTo(expected);
    }

    @ParameterizedTest
    @CsvSource({"소연,소연 님", "Mina,Mina 님"})
    void honorific_POLITE는_님을_붙인다(String nickname, String expected) {
        assertThat(GreetingSpeech.POLITE.honorific(nickname)).isEqualTo(expected);
    }

    @Test
    void defaultMessageKey_말투별_설정_키() {
        assertThat(GreetingSpeech.CASUAL.defaultMessageKey()).isEqualTo(SettingKey.GREETING_DEFAULT_MESSAGE_CASUAL);
        assertThat(GreetingSpeech.POLITE.defaultMessageKey()).isEqualTo(SettingKey.GREETING_DEFAULT_MESSAGE_POLITE);
    }

}
