package kr.co.teeq.api.onboarding.core.constant;

import static kr.co.teeq.api.onboarding.core.constant.OnboardingQuestion.ADVICE_STYLE;
import static kr.co.teeq.api.onboarding.core.constant.OnboardingQuestion.AVOID_BEHAVIOR;
import static kr.co.teeq.api.onboarding.core.constant.OnboardingQuestion.CONVERSATION_LEAD;
import static kr.co.teeq.api.onboarding.core.constant.OnboardingQuestion.PERSONALITY;
import static kr.co.teeq.api.onboarding.core.constant.OnboardingQuestion.RELATIONSHIP;
import static kr.co.teeq.api.onboarding.core.constant.OnboardingQuestion.SPEECH_STYLE;
import static kr.co.teeq.api.onboarding.core.constant.OnboardingQuestion.VOICE_TONE;

import java.util.Arrays;
import java.util.List;

/**
 * 온보딩 선택지. 상수 이름은 {@code <질문>_<접미사>}이고, 선언 순서가 시안의 선택지 순서이다.
 */
public enum OnboardingOption {

    RELATIONSHIP_CLOSE_FRIEND(RELATIONSHIP),
    RELATIONSHIP_RELIABLE_FRIEND(RELATIONSHIP),
    RELATIONSHIP_SWEET_PARTNER(RELATIONSHIP),
    RELATIONSHIP_LIFE_MENTOR(RELATIONSHIP),

    PERSONALITY_MOOD_MAKER(PERSONALITY),
    PERSONALITY_PLAYFUL_JOKER(PERSONALITY),
    PERSONALITY_CALM_WARM(PERSONALITY),
    PERSONALITY_FREE_SPIRIT(PERSONALITY),

    SPEECH_STYLE_CLOSE_FRIEND_CASUAL(SPEECH_STYLE),
    SPEECH_STYLE_AFFECTIONATE_CASUAL(SPEECH_STYLE),
    SPEECH_STYLE_GENTLE_POLITE(SPEECH_STYLE),

    VOICE_TONE_HIGH_BRIGHT(VOICE_TONE),
    VOICE_TONE_MID_NATURAL(VOICE_TONE),
    VOICE_TONE_MID_LOW_CALM(VOICE_TONE),
    VOICE_TONE_LOW_DEEP(VOICE_TONE),

    ADVICE_STYLE_EMPATHY_ONLY(ADVICE_STYLE),
    ADVICE_STYLE_REALISTIC_ADVICE_ONLY(ADVICE_STYLE),
    ADVICE_STYLE_TAKE_MY_SIDE(ADVICE_STYLE),
    ADVICE_STYLE_BALANCED(ADVICE_STYLE),

    CONVERSATION_LEAD_LISTENER(CONVERSATION_LEAD),
    CONVERSATION_LEAD_BALANCED(CONVERSATION_LEAD),
    CONVERSATION_LEAD_LEADER(CONVERSATION_LEAD),

    AVOID_BEHAVIOR_RAPID_QUESTIONS(AVOID_BEHAVIOR),
    AVOID_BEHAVIOR_UNASKED_ADVICE(AVOID_BEHAVIOR),
    AVOID_BEHAVIOR_EXCESSIVE_POSITIVITY(AVOID_BEHAVIOR),
    AVOID_BEHAVIOR_REPEATED_RESPONSES(AVOID_BEHAVIOR),
    AVOID_BEHAVIOR_INTERRUPTING(AVOID_BEHAVIOR);

    private final OnboardingQuestion question;

    OnboardingOption(OnboardingQuestion question) {
        this.question = question;
    }

    public OnboardingQuestion question() {
        return question;
    }

    // 해당 질문에 속한 선택지를 선언 순서대로 반환한다
    public static List<OnboardingOption> of(OnboardingQuestion question) {
        return Arrays.stream(values())
            .filter(option -> option.question == question)
            .toList();
    }

}
