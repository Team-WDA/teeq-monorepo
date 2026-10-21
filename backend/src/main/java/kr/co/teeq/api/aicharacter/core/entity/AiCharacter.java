package kr.co.teeq.api.aicharacter.core.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.util.List;
import kr.co.teeq.api.aicharacter.core.constant.AiCharacterValidation;
import kr.co.teeq.api.common.core.constant.CharacterType;
import kr.co.teeq.api.common.core.entity.BaseEntity;
import kr.co.teeq.api.member.core.entity.Member;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 회원의 AI 캐릭터. 회원당 하나이고, 다시 생성할 때는 같은 행의 캐릭터 유형과 성향 태그를 덮어쓴다.
 * 이름이 확정되기 전에는 name이 null이다.
 * 삭제 경로가 없는 hard delete 전제라 {@code deleted}는 항상 false이며, unique도 전체 행에 걸린다.
 */
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
@Table(name = "ai_character")
public class AiCharacter extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "member_id", nullable = false)
    private Member member;

    @Column(length = 10)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(name = "character_type", nullable = false, length = 20)
    private CharacterType characterType;

    @Column(name = "personality_tag_1", nullable = false, length = AiCharacterValidation.PERSONALITY_TAG_MAX_LENGTH)
    private String personalityTag1;

    @Column(name = "personality_tag_2", nullable = false, length = AiCharacterValidation.PERSONALITY_TAG_MAX_LENGTH)
    private String personalityTag2;

    @Column(name = "personality_tag_3", nullable = false, length = AiCharacterValidation.PERSONALITY_TAG_MAX_LENGTH)
    private String personalityTag3;

    private AiCharacter(Member member, CharacterType characterType, List<String> personalityTags) {
        this.member = member;
        regenerate(characterType, personalityTags);
    }

    public static AiCharacter of(Member member, CharacterType characterType, List<String> personalityTags) {
        return new AiCharacter(member, characterType, personalityTags);
    }

    // 이름은 유지하고 캐릭터 유형과 성향 태그만 바꾼다
    public void regenerate(CharacterType characterType, List<String> personalityTags) {
        if (personalityTags.size() != AiCharacterValidation.PERSONALITY_TAG_COUNT) {
            throw new IllegalArgumentException("성향 태그는 정확히 " + AiCharacterValidation.PERSONALITY_TAG_COUNT + "개여야 합니다");
        }
        this.characterType = characterType;
        this.personalityTag1 = personalityTags.get(0);
        this.personalityTag2 = personalityTags.get(1);
        this.personalityTag3 = personalityTags.get(2);
    }

    public void rename(String name) {
        this.name = name;
    }

    public boolean isNamed() {
        return name != null;
    }

    public List<String> getPersonalityTags() {
        return List.of(personalityTag1, personalityTag2, personalityTag3);
    }

}
