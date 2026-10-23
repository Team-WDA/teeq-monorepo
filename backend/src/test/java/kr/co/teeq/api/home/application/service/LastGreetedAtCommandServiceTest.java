package kr.co.teeq.api.home.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.BDDMockito.given;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.repository.MemberRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class LastGreetedAtCommandServiceTest {

    private static final UUID MEMBER_ID = UUID.randomUUID();
    private static final Instant NOW = Instant.parse("2026-10-21T01:00:00Z");

    @Mock
    private MemberRepository memberRepository;

    private LastGreetedAtCommandService lastGreetedAtCommandService;

    @BeforeEach
    void setUp() {
        lastGreetedAtCommandService =
            new LastGreetedAtCommandService(memberRepository, Clock.fixed(NOW, ZoneOffset.UTC));
    }

    @Test
    void record_다시_조회한_회원에_현재_시각을_기록한다() {
        Member member = Member.createSocialMember(LoginType.APPLE, "apple-subject", "soyeon@teeq.com", "소연");
        given(memberRepository.findByIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.of(member));

        lastGreetedAtCommandService.record(MEMBER_ID);

        assertThat(member.getLastGreetedAt()).isEqualTo(NOW);
    }

    @Test
    void record_회원이_없으면_MEMBER_NOT_FOUND() {
        given(memberRepository.findByIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.empty());

        assertThatThrownBy(() -> lastGreetedAtCommandService.record(MEMBER_ID))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.MEMBER_NOT_FOUND));
    }

}
