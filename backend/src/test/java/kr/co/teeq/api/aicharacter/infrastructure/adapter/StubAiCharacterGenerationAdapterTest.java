package kr.co.teeq.api.aicharacter.infrastructure.adapter;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import kr.co.teeq.api.aicharacter.core.constant.AiCharacterValidation;
import kr.co.teeq.api.aicharacter.core.port.GeneratedAiCharacter;
import kr.co.teeq.api.common.core.constant.CharacterType;
import kr.co.teeq.api.onboarding.core.constant.OnboardingOption;
import kr.co.teeq.api.onboarding.core.constant.OnboardingQuestion;
import org.junit.jupiter.api.Test;

class StubAiCharacterGenerationAdapterTest {

    private static final int PERSONA_ID_MAX_LENGTH = 64;

    private final StubAiCharacterGenerationAdapter adapter = new StubAiCharacterGenerationAdapter();

    @Test
    void 항상_같은_캐릭터를_돌려준다() {
        GeneratedAiCharacter generated = adapter.generate(UUID.randomUUID(), new EnumMap<>(OnboardingQuestion.class));

        assertThat(generated.personaId()).isEqualTo("stub-persona");
        assertThat(generated.characterType()).isEqualTo(CharacterType.CHARACTER_1);
        assertThat(generated.personalityTags()).containsExactly("다정한", "차분한", "호기심 많은");
    }

    @Test
    void 온보딩_답변과_회원이_달라도_결과가_같다() {
        Map<OnboardingQuestion, List<OnboardingOption>> emptyAnswers = new EnumMap<>(OnboardingQuestion.class);
        Map<OnboardingQuestion, List<OnboardingOption>> filledAnswers = new EnumMap<>(OnboardingQuestion.class);
        OnboardingQuestion question = OnboardingQuestion.values()[0];
        filledAnswers.put(question, List.of(OnboardingOption.values()[0]));

        GeneratedAiCharacter first = adapter.generate(UUID.randomUUID(), emptyAnswers);
        GeneratedAiCharacter second = adapter.generate(UUID.randomUUID(), filledAnswers);

        assertThat(first).isEqualTo(second);
    }

    @Test
    void 고정_값이_기존_응답_검증_규칙을_지킨다() {
        GeneratedAiCharacter generated = adapter.generate(UUID.randomUUID(), new EnumMap<>(OnboardingQuestion.class));

        assertThat(generated.personalityTags()).hasSize(AiCharacterValidation.PERSONALITY_TAG_COUNT);
        assertThat(generated.personalityTags()).allSatisfy(tag -> {
            assertThat(tag).isNotBlank();
            assertThat(tag.length()).isLessThanOrEqualTo(AiCharacterValidation.PERSONALITY_TAG_MAX_LENGTH);
            assertThat(tag.chars().anyMatch(Character::isISOControl)).isFalse();
        });
        assertThat(generated.personaId()).isNotBlank();
        assertThat(generated.personaId().length()).isLessThanOrEqualTo(PERSONA_ID_MAX_LENGTH);
        assertThat(generated.personaId().chars().anyMatch(Character::isISOControl)).isFalse();
    }

}
