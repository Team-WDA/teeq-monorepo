package kr.co.teeq.api.aicharacter.application.handler;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.BDDMockito.given;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.aicharacter.core.entity.AiCharacter;
import kr.co.teeq.api.aicharacter.core.repository.AiCharacterRepository;
import kr.co.teeq.api.common.core.constant.CharacterType;
import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.event.MemberDeletedEvent;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class AiCharacterMemberDeletionHandlerTest {

    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final Instant NOW = Instant.parse("2026-10-22T03:00:00Z");

    @Mock
    private AiCharacterRepository aiCharacterRepository;

    private AiCharacterMemberDeletionHandler handler;

    @BeforeEach
    void setUp() {
        handler = new AiCharacterMemberDeletionHandler(aiCharacterRepository, Clock.fixed(NOW, ZoneOffset.UTC));
    }

    @Test
    void handle_softDeletesCharacter() {
        Member member = Member.createSocialMember(LoginType.APPLE, "social-id", "a@b.c", "소연");
        AiCharacter aiCharacter = AiCharacter.of(member, CharacterType.CHARACTER_1, List.of("태그1", "태그2", "태그3"));
        given(aiCharacterRepository.findByMemberId(MEMBER_ID)).willReturn(Optional.of(aiCharacter));

        handler.handle(new MemberDeletedEvent(MEMBER_ID));

        assertThat(aiCharacter.isDeleted()).isTrue();
        assertThat(aiCharacter.getDeletedAt()).isEqualTo(NOW);
    }

    @Test
    void handle_noCharacter_doesNothing() {
        given(aiCharacterRepository.findByMemberId(MEMBER_ID)).willReturn(Optional.empty());

        assertThatCode(() -> handler.handle(new MemberDeletedEvent(MEMBER_ID))).doesNotThrowAnyException();
    }

}
