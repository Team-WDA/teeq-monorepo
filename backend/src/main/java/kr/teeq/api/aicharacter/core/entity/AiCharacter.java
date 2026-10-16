package kr.teeq.api.aicharacter.core.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import java.util.List;
import java.util.UUID;
import kr.teeq.api.aicharacter.core.constant.AiCharacterValidation;
import kr.teeq.api.common.core.entity.BaseEntity;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 회원의 AI 캐릭터. 회원당 하나이고, 다시 설정할 때는 같은 행의 값을 덮어쓴다.
 * 삭제 경로가 없는 hard delete 전제라 {@code deleted}는 항상 false이며, unique도 전체 행에 걸린다.
 */
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
@Table(name = "ai_character")
public class AiCharacter extends BaseEntity {

    @Column(nullable = false)
    private UUID memberId;

    @Column(nullable = false, length = 10)
    private String name;

    @Column(nullable = false)
    private int characterNumber;

    @Column(name = "personality_tag_1", nullable = false, length = AiCharacterValidation.PERSONALITY_TAG_MAX_LENGTH)
    private String personalityTag1;

    @Column(name = "personality_tag_2", nullable = false, length = AiCharacterValidation.PERSONALITY_TAG_MAX_LENGTH)
    private String personalityTag2;

    @Column(name = "personality_tag_3", nullable = false, length = AiCharacterValidation.PERSONALITY_TAG_MAX_LENGTH)
    private String personalityTag3;

    private AiCharacter(UUID memberId, String name, int characterNumber, List<String> personalityTags) {
        this.memberId = memberId;
        reset(name, characterNumber, personalityTags);
    }

    public static AiCharacter of(UUID memberId, String name, int characterNumber, List<String> personalityTags) {
        return new AiCharacter(memberId, name, characterNumber, personalityTags);
    }

    public void reset(String name, int characterNumber, List<String> personalityTags) {
        if (personalityTags.size() != AiCharacterValidation.PERSONALITY_TAG_COUNT) {
            throw new IllegalArgumentException("성향 태그는 정확히 " + AiCharacterValidation.PERSONALITY_TAG_COUNT + "개여야 합니다");
        }
        this.name = name;
        this.characterNumber = characterNumber;
        this.personalityTag1 = personalityTags.get(0);
        this.personalityTag2 = personalityTags.get(1);
        this.personalityTag3 = personalityTags.get(2);
    }

    public List<String> getPersonalityTags() {
        return List.of(personalityTag1, personalityTag2, personalityTag3);
    }

}
