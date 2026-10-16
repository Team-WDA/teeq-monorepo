package kr.teeq.api.onboarding.core.constant;

/**
 * 온보딩 질문. 선언 순서가 시안의 질문 순서이며, 질문마다 선택 가능한 개수 범위를 가진다.
 */
public enum OnboardingQuestion {

    RELATIONSHIP(1, 1),
    PERSONALITY(1, 1),
    SPEECH_STYLE(1, 1),
    VOICE_TONE(1, 1),
    ADVICE_STYLE(1, 1),
    CONVERSATION_LEAD(1, 1),
    AVOID_BEHAVIOR(1, 5);

    private final int minSelections;
    private final int maxSelections;

    OnboardingQuestion(int minSelections, int maxSelections) {
        this.minSelections = minSelections;
        this.maxSelections = maxSelections;
    }

    public int minSelections() {
        return minSelections;
    }

    public int maxSelections() {
        return maxSelections;
    }

}
