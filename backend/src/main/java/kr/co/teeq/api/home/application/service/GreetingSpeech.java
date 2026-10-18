package kr.co.teeq.api.home.application.service;

import kr.co.teeq.api.onboarding.core.constant.OnboardingOption;
import kr.co.teeq.api.setting.core.constant.SettingKey;

/**
 * 오늘의 한마디의 말투. 온보딩 말투 선택지를 반말·존댓말 두 가지로 묶고 호칭 규칙을 갖는다.
 */
public enum GreetingSpeech {

    CASUAL(SettingKey.GREETING_DEFAULT_MESSAGE_CASUAL),
    POLITE(SettingKey.GREETING_DEFAULT_MESSAGE_POLITE);

    private static final char HANGUL_FIRST = '가';
    private static final char HANGUL_LAST = '힣';
    private static final int FINAL_CONSONANT_COUNT = 28;
    private static final String POLITE_SUFFIX = " 님";

    private final SettingKey defaultMessageKey;

    GreetingSpeech(SettingKey defaultMessageKey) {
        this.defaultMessageKey = defaultMessageKey;
    }

    public static GreetingSpeech from(OnboardingOption speechStyle) {
        return switch (speechStyle) {
            case SPEECH_STYLE_CLOSE_FRIEND_CASUAL, SPEECH_STYLE_AFFECTIONATE_CASUAL -> CASUAL;
            case SPEECH_STYLE_GENTLE_POLITE -> POLITE;
            default -> throw new IllegalArgumentException("말투 선택지가 아닙니다: " + speechStyle);
        };
    }

    public SettingKey defaultMessageKey() {
        return defaultMessageKey;
    }

    public String honorific(String nickname) {
        if (this == POLITE) {
            return nickname + POLITE_SUFFIX;
        }
        char last = nickname.charAt(nickname.length() - 1);
        if (last < HANGUL_FIRST || last > HANGUL_LAST) {
            return nickname;
        }
        boolean hasFinalConsonant = (last - HANGUL_FIRST) % FINAL_CONSONANT_COUNT != 0;
        return nickname + (hasFinalConsonant ? "아" : "야");
    }

}
