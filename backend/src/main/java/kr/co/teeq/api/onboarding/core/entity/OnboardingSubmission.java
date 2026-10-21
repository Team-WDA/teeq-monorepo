package kr.co.teeq.api.onboarding.core.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.util.List;
import kr.co.teeq.api.common.core.constant.CharacterType;
import kr.co.teeq.api.common.core.entity.BaseEntity;
import kr.co.teeq.api.member.core.entity.Member;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 온보딩 제출 1회. 그 제출로 만들어진 캐릭터 결과를 함께 기록하며, 답변 행이 이 제출을 가리킨다.
 */
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
@Table(name = "onboarding_submission")
public class OnboardingSubmission extends BaseEntity {

    private static final int PERSONALITY_TAG_COUNT = 3;

    private static final int PERSONA_ID_MAX_LENGTH = 64;

    // ai_character의 성향 태그 컬럼과 같은 길이. onboarding은 aicharacter를 import할 수 없어 따로 둔다
    private static final int PERSONALITY_TAG_MAX_LENGTH = 50;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "member_id", nullable = false)
    private Member member;

    @Column(name = "persona_id", nullable = false, length = PERSONA_ID_MAX_LENGTH)
    private String personaId;

    @Enumerated(EnumType.STRING)
    @Column(name = "character_type", nullable = false, length = 20)
    private CharacterType characterType;

    @Column(name = "personality_tag_1", nullable = false, length = PERSONALITY_TAG_MAX_LENGTH)
    private String personalityTag1;

    @Column(name = "personality_tag_2", nullable = false, length = PERSONALITY_TAG_MAX_LENGTH)
    private String personalityTag2;

    @Column(name = "personality_tag_3", nullable = false, length = PERSONALITY_TAG_MAX_LENGTH)
    private String personalityTag3;

    private OnboardingSubmission(Member member, String personaId, CharacterType characterType,
        List<String> personalityTags) {
        if (personalityTags.size() != PERSONALITY_TAG_COUNT) {
            throw new IllegalArgumentException("성향 태그는 정확히 " + PERSONALITY_TAG_COUNT + "개여야 합니다");
        }
        this.member = member;
        this.personaId = personaId;
        this.characterType = characterType;
        this.personalityTag1 = personalityTags.get(0);
        this.personalityTag2 = personalityTags.get(1);
        this.personalityTag3 = personalityTags.get(2);
    }

    public static OnboardingSubmission of(Member member, String personaId, CharacterType characterType,
        List<String> personalityTags) {
        return new OnboardingSubmission(member, personaId, characterType, personalityTags);
    }

    public List<String> getPersonalityTags() {
        return List.of(personalityTag1, personalityTag2, personalityTag3);
    }

}
