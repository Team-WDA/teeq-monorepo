package kr.co.teeq.api.member.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.verify;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.entity.ProfileImage;
import kr.co.teeq.api.member.core.repository.ProfileImageRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InOrder;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;

@ExtendWith(MockitoExtension.class)
class ProfileImageCommandServiceTest {

    private static final Instant NOW = Instant.parse("2026-10-17T00:00:00Z");
    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");

    @Mock
    private ProfileImageRepository profileImageRepository;

    @Mock
    private Member member;

    private ProfileImageCommandService commandService;

    @BeforeEach
    void setUp() {
        commandService = new ProfileImageCommandService(profileImageRepository, Clock.fixed(NOW, ZoneOffset.UTC));
    }

    @Test
    void replace_softDeletesAndFlushesPreviousRowBeforeSavingNewRow() {
        given(member.getId()).willReturn(MEMBER_ID);
        ProfileImage previous = ProfileImage.of(member, "old.jpg", "image/jpeg", 10L);
        given(profileImageRepository.findByMemberIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.of(previous));

        commandService.replace(member, "new.png", "image/png", 20L);

        assertThat(previous.isDeleted()).isTrue();
        assertThat(previous.getDeletedAt()).isEqualTo(NOW);
        InOrder order = inOrder(profileImageRepository);
        order.verify(profileImageRepository).saveAndFlush(previous);
        order.verify(profileImageRepository).saveAndFlush(any(ProfileImage.class));
    }

    @Test
    void replace_concurrentReplaceOnActiveIndex_mapsToStateConflict() {
        given(member.getId()).willReturn(MEMBER_ID);
        given(profileImageRepository.findByMemberIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.empty());
        given(profileImageRepository.saveAndFlush(any(ProfileImage.class))).willThrow(
            new DataIntegrityViolationException("constraint", new RuntimeException(
                "duplicate key value violates unique constraint \"uq_profile_image_member_active\"")));

        assertThatThrownBy(() -> commandService.replace(member, "new.png", "image/png", 20L))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
    }

    @Test
    void delete_withActiveRow_softDeletesIt() {
        given(member.getId()).willReturn(MEMBER_ID);
        ProfileImage current = ProfileImage.of(member, "old.jpg", "image/jpeg", 10L);
        given(profileImageRepository.findByMemberIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.of(current));

        commandService.delete(member);

        assertThat(current.isDeleted()).isTrue();
    }

    @Test
    void delete_withoutActiveRow_doesNothing() {
        given(member.getId()).willReturn(MEMBER_ID);
        given(profileImageRepository.findByMemberIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.empty());

        commandService.delete(member);

        verify(profileImageRepository).findByMemberIdAndDeletedFalse(MEMBER_ID);
    }

}
