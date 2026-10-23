package kr.co.teeq.api.member.application.handler;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.BDDMockito.given;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.entity.ProfileImage;
import kr.co.teeq.api.member.core.event.MemberDeletedEvent;
import kr.co.teeq.api.member.core.repository.ProfileImageRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class ProfileImageMemberDeletionHandlerTest {

    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final Instant NOW = Instant.parse("2026-10-22T03:00:00Z");

    @Mock
    private ProfileImageRepository profileImageRepository;

    private ProfileImageMemberDeletionHandler handler;

    @BeforeEach
    void setUp() {
        handler = new ProfileImageMemberDeletionHandler(profileImageRepository, Clock.fixed(NOW, ZoneOffset.UTC));
    }

    @Test
    void handle_softDeletesActiveProfileImage() {
        Member member = Member.createMember(LoginType.APPLE, "social-id", "a@b.c", "소연");
        ProfileImage profileImage = ProfileImage.of(member, "storage-key", "image/png", 1024L);
        given(profileImageRepository.findByMemberIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.of(profileImage));

        handler.handle(new MemberDeletedEvent(MEMBER_ID));

        assertThat(profileImage.isDeleted()).isTrue();
        assertThat(profileImage.getDeletedAt()).isEqualTo(NOW);
    }

    @Test
    void handle_noImage_doesNothing() {
        given(profileImageRepository.findByMemberIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.empty());

        assertThatCode(() -> handler.handle(new MemberDeletedEvent(MEMBER_ID))).doesNotThrowAnyException();
    }

}
