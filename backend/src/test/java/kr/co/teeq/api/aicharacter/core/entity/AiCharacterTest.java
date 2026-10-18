package kr.co.teeq.api.aicharacter.core.entity;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class AiCharacterTest {

    private static final UUID MEMBER_ID = UUID.randomUUID();

    @Test
    void 생성하면_이름이_없는_캐릭터를_만든다() {
        AiCharacter aiCharacter = AiCharacter.of(MEMBER_ID, 7, List.of("a", "b", "c"));

        assertThat(aiCharacter.isNamed()).isFalse();
        assertThat(aiCharacter.getName()).isNull();
        assertThat(aiCharacter.getMemberId()).isEqualTo(MEMBER_ID);
        assertThat(aiCharacter.getCharacterNumber()).isEqualTo(7);
        assertThat(aiCharacter.getPersonalityTags()).containsExactly("a", "b", "c");
    }

    @Test
    void 재생성해도_기존_이름을_유지한다() {
        AiCharacter aiCharacter = AiCharacter.of(MEMBER_ID, 1, List.of("x", "y", "z"));
        aiCharacter.rename("티큐");

        aiCharacter.regenerate(7, List.of("a", "b", "c"));

        assertThat(aiCharacter.getName()).isEqualTo("티큐");
        assertThat(aiCharacter.getCharacterNumber()).isEqualTo(7);
        assertThat(aiCharacter.getPersonalityTags()).containsExactly("a", "b", "c");
    }

    @Test
    void 재생성할_때_성격_태그_개수가_틀리면_거부한다() {
        AiCharacter aiCharacter = AiCharacter.of(MEMBER_ID, 1, List.of("x", "y", "z"));

        assertThatThrownBy(() -> aiCharacter.regenerate(7, List.of("a", "b")))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void 이름을_지정하면_이름이_설정되고_이름_있는_상태가_된다() {
        AiCharacter aiCharacter = AiCharacter.of(MEMBER_ID, 1, List.of("x", "y", "z"));

        aiCharacter.rename("티큐");

        assertThat(aiCharacter.getName()).isEqualTo("티큐");
        assertThat(aiCharacter.isNamed()).isTrue();
    }

}
