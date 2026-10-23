package kr.co.teeq.api.call.application.handler;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.call.core.constant.CallStatus;
import kr.co.teeq.api.call.core.constant.LimitKind;
import kr.co.teeq.api.call.core.entity.CallBonus;
import kr.co.teeq.api.call.core.entity.CallHistory;
import kr.co.teeq.api.call.core.repository.CallBonusRepository;
import kr.co.teeq.api.call.core.repository.CallHistoryRepository;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.event.MemberDeletedEvent;
import kr.co.teeq.api.setting.application.service.SettingConfigService;
import kr.co.teeq.api.setting.core.constant.SettingKey;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class CallMemberDeletionHandlerTest {

    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final Instant NOW = Instant.parse("2026-10-22T03:00:00Z");
    private static final long MAX_SECONDS_PER_SESSION = 3600L;
    private static final Instant ACTIVE_CUTOFF = NOW.minusSeconds(MAX_SECONDS_PER_SESSION);

    @Mock
    private CallHistoryRepository callHistoryRepository;

    @Mock
    private CallBonusRepository callBonusRepository;

    @Mock
    private SettingConfigService settingConfigService;

    private CallMemberDeletionHandler handler;

    @BeforeEach
    void setUp() {
        Clock clock = Clock.fixed(NOW, ZoneOffset.UTC);
        handler = new CallMemberDeletionHandler(callHistoryRepository, callBonusRepository, settingConfigService,
            clock);
        given(settingConfigService.getInt(SettingKey.CALL_MAX_SECONDS_PER_SESSION))
            .willReturn(MAX_SECONDS_PER_SESSION);
    }

    private CallHistory callHistory(Instant startedAt) {
        Member member = Member.createMember(LoginType.APPLE, "social-id", "a@b.c", "소연");
        return CallHistory.pending(member, "persona-id", LimitKind.PER_CALL, startedAt);
    }

    private CallBonus callBonus() {
        Member member = Member.createMember(LoginType.APPLE, "social-id", "a@b.c", "소연");
        return CallBonus.grant(member, LocalDate.of(2026, 10, 22), 600, "보상", null);
    }

    @Test
    void handle_activeCallWithinLimit_throwsMemberHasActiveCall() {
        given(callHistoryRepository.existsByMemberIdAndStatusInAndStartedAtGreaterThanAndDeletedFalse(
            MEMBER_ID, CallStatus.ACTIVE_STATUSES, ACTIVE_CUTOFF)).willReturn(true);

        assertThatThrownBy(() -> handler.handle(new MemberDeletedEvent(MEMBER_ID)))
            .isInstanceOf(CustomException.class)
            .extracting(exception -> ((CustomException) exception).getErrorCode())
            .isEqualTo(ErrorCode.MEMBER_HAS_ACTIVE_CALL);
        verify(callHistoryRepository, never()).findByMemberIdAndDeletedFalse(MEMBER_ID);
        verify(callBonusRepository, never()).findByMemberIdAndDeletedFalse(MEMBER_ID);
    }

    @Test
    void handle_noActiveCall_softDeletesCallHistoriesAndBonuses() {
        CallHistory firstCall = callHistory(NOW.minusSeconds(7200));
        CallHistory secondCall = callHistory(NOW.minusSeconds(10800));
        CallBonus bonus = callBonus();
        given(callHistoryRepository.existsByMemberIdAndStatusInAndStartedAtGreaterThanAndDeletedFalse(
            MEMBER_ID, CallStatus.ACTIVE_STATUSES, ACTIVE_CUTOFF)).willReturn(false);
        given(callHistoryRepository.findByMemberIdAndDeletedFalse(MEMBER_ID))
            .willReturn(List.of(firstCall, secondCall));
        given(callBonusRepository.findByMemberIdAndDeletedFalse(MEMBER_ID)).willReturn(List.of(bonus));

        handler.handle(new MemberDeletedEvent(MEMBER_ID));

        assertThat(List.of(firstCall, secondCall)).allSatisfy(call -> {
            assertThat(call.isDeleted()).isTrue();
            assertThat(call.getDeletedAt()).isEqualTo(NOW);
        });
        assertThat(bonus.isDeleted()).isTrue();
        assertThat(bonus.getDeletedAt()).isEqualTo(NOW);
    }

    @Test
    void handle_staleActiveCallBeyondLimit_doesNotBlockAndIsDeleted() {
        CallHistory staleCall = callHistory(NOW.minusSeconds(MAX_SECONDS_PER_SESSION + 600));
        staleCall.activate("session-id", null, null);
        given(callHistoryRepository.existsByMemberIdAndStatusInAndStartedAtGreaterThanAndDeletedFalse(
            MEMBER_ID, CallStatus.ACTIVE_STATUSES, ACTIVE_CUTOFF)).willReturn(false);
        given(callHistoryRepository.findByMemberIdAndDeletedFalse(MEMBER_ID)).willReturn(List.of(staleCall));
        given(callBonusRepository.findByMemberIdAndDeletedFalse(MEMBER_ID)).willReturn(List.of());

        handler.handle(new MemberDeletedEvent(MEMBER_ID));

        assertThat(staleCall.getStatus()).isEqualTo(CallStatus.IN_PROGRESS);
        assertThat(staleCall.isDeleted()).isTrue();
        assertThat(staleCall.getDeletedAt()).isEqualTo(NOW);
    }

}
