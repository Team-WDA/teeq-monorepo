package kr.teeq.api.call.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kr.teeq.api.call.application.dto.request.CallBonusGrantRequest;
import kr.teeq.api.call.application.dto.response.CallBonusResponse;
import kr.teeq.api.call.core.entity.CallBonus;
import kr.teeq.api.call.core.repository.CallBonusRepository;
import kr.teeq.api.common.core.exception.CustomException;
import kr.teeq.api.common.core.exception.ErrorCode;
import kr.teeq.api.member.core.entity.Member;
import kr.teeq.api.member.core.repository.MemberRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class CallBonusServiceTest {

    // UTC 기준으로는 10-17이지만 KST 기준으로는 10-18 00:30이다
    private static final Instant NOW = Instant.parse("2026-10-17T15:30:00Z");
    private static final LocalDate KST_TODAY = LocalDate.of(2026, 10, 18);

    private final UUID memberId = UUID.randomUUID();
    private final UUID adminId = UUID.randomUUID();

    @Mock
    private CallBonusRepository callBonusRepository;

    @Mock
    private MemberRepository memberRepository;

    @Mock
    private Member member;

    private CallBonusService createService() {
        return new CallBonusService(callBonusRepository, memberRepository, Clock.fixed(NOW, ZoneOffset.UTC),
            ZoneId.of("Asia/Seoul"));
    }

    private void stubMemberExists() {
        given(memberRepository.findByIdAndDeletedFalse(memberId)).willReturn(Optional.of(member));
    }

    private void stubSaveReturnsArgument() {
        given(callBonusRepository.save(any(CallBonus.class))).willAnswer(invocation -> invocation.getArgument(0));
    }

    @Test
    void grant_withoutBonusDate_usesKoreaToday() {
        stubMemberExists();
        stubSaveReturnsArgument();

        CallBonusResponse response = createService().grant(memberId, adminId,
            new CallBonusGrantRequest(600, null, "장애 보상"));

        assertThat(response.bonusDate()).isEqualTo(KST_TODAY);
        assertThat(response.memberId()).isEqualTo(memberId);
        assertThat(response.seconds()).isEqualTo(600);
        assertThat(response.reason()).isEqualTo("장애 보상");
        assertThat(response.grantedByMemberId()).isEqualTo(adminId);
        assertThat(response.canceled()).isFalse();
    }

    @Test
    void grant_todayAndFutureDate_allowed() {
        stubMemberExists();
        stubSaveReturnsArgument();

        CallBonusResponse today = createService().grant(memberId, adminId,
            new CallBonusGrantRequest(60, KST_TODAY, "오늘"));
        CallBonusResponse future = createService().grant(memberId, adminId,
            new CallBonusGrantRequest(60, KST_TODAY.plusDays(3), "미래"));

        assertThat(today.bonusDate()).isEqualTo(KST_TODAY);
        assertThat(future.bonusDate()).isEqualTo(KST_TODAY.plusDays(3));
    }

    @Test
    void grant_pastDate_rejected() {
        stubMemberExists();

        assertThatThrownBy(() -> createService().grant(memberId, adminId,
            new CallBonusGrantRequest(60, KST_TODAY.minusDays(1), "과거")))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.INVALID_REQUEST));
        verify(callBonusRepository, never()).save(any());
    }

    @Test
    void grant_memberNotFound_throws() {
        given(memberRepository.findByIdAndDeletedFalse(memberId)).willReturn(Optional.empty());

        assertThatThrownBy(() -> createService().grant(memberId, adminId,
            new CallBonusGrantRequest(60, null, "사유")))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.MEMBER_NOT_FOUND));
        verify(callBonusRepository, never()).save(any());
    }

    @Test
    void getAll_includesCanceledRows() {
        CallBonus active = CallBonus.grant(memberId, KST_TODAY, 60, "유효", adminId);
        CallBonus canceled = CallBonus.grant(memberId, KST_TODAY, 120, "취소됨", adminId);
        canceled.cancel(adminId, Clock.fixed(NOW, ZoneOffset.UTC));
        given(callBonusRepository.findByMemberIdOrderByCreatedAtDesc(memberId))
            .willReturn(List.of(active, canceled));

        List<CallBonusResponse> responses = createService().getAll(memberId);

        assertThat(responses).extracting(CallBonusResponse::canceled).containsExactly(false, true);
        assertThat(responses.get(1).canceledAt()).isEqualTo(NOW);
        assertThat(responses.get(1).canceledByMemberId()).isEqualTo(adminId);
    }

    @Test
    void cancel_recordsCanceler() {
        UUID callBonusId = UUID.randomUUID();
        UUID cancelerId = UUID.randomUUID();
        CallBonus callBonus = CallBonus.grant(memberId, KST_TODAY, 60, "사유", adminId);
        given(callBonusRepository.findByIdAndMemberIdAndDeletedFalse(callBonusId, memberId))
            .willReturn(Optional.of(callBonus));

        createService().cancel(memberId, callBonusId, cancelerId);

        assertThat(callBonus.isDeleted()).isTrue();
        assertThat(callBonus.getDeletedAt()).isEqualTo(NOW);
        assertThat(callBonus.getCanceledByMemberId()).isEqualTo(cancelerId);
    }

    @Test
    void cancel_notFoundOrAlreadyCanceledOrOtherMember_throws() {
        UUID callBonusId = UUID.randomUUID();
        given(callBonusRepository.findByIdAndMemberIdAndDeletedFalse(callBonusId, memberId))
            .willReturn(Optional.empty());

        assertThatThrownBy(() -> createService().cancel(memberId, callBonusId, adminId))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.CALL_BONUS_NOT_FOUND));
    }

}
