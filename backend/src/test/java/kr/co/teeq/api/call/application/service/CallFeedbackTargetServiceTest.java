package kr.co.teeq.api.call.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

import java.time.Instant;
import java.util.Collection;
import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.call.application.dto.response.FeedbackTargetCall;
import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.call.application.dto.response.LatestFeedbackableCall;
import kr.co.teeq.api.call.core.constant.CallStatus;
import kr.co.teeq.api.call.core.constant.LimitKind;
import kr.co.teeq.api.call.core.entity.CallHistory;
import kr.co.teeq.api.call.core.repository.CallHistoryRepository;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.entity.Member;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class CallFeedbackTargetServiceTest {

    private static final String CALL_SESSION_ID = "call-session-1";
    private static final Instant STARTED_AT = Instant.parse("2026-10-16T03:00:00Z");

    private final UUID memberId = UUID.randomUUID();
    private final Member member = memberOf(memberId);
    private final UUID callHistoryId = UUID.randomUUID();

    @Mock
    private CallHistoryRepository callHistoryRepository;

    private CallFeedbackTargetService createService() {
        return new CallFeedbackTargetService(callHistoryRepository);
    }

    private static Member memberOf(UUID id) {
        Member owner = Member.createMember(LoginType.GOOGLE, "google-uid", "soyeon@teeq.com", "소연");
        ReflectionTestUtils.setField(owner, "id", id);
        return owner;
    }

    private CallHistory callHistoryOf(Member owner, CallStatus status) {
        CallHistory callHistory = CallHistory.pending(owner, "persona-1", LimitKind.PER_DAY, STARTED_AT);
        ReflectionTestUtils.setField(callHistory, "id", callHistoryId);
        ReflectionTestUtils.setField(callHistory, "callSessionId", CALL_SESSION_ID);
        ReflectionTestUtils.setField(callHistory, "status", status);
        return callHistory;
    }

    private void stubFound(CallHistory callHistory) {
        given(callHistoryRepository.findByCallSessionIdAndDeletedFalse(CALL_SESSION_ID))
            .willReturn(Optional.of(callHistory));
    }

    @Test
    void getFeedbackTarget_unknownSession_throwsCallSessionNotFound() {
        given(callHistoryRepository.findByCallSessionIdAndDeletedFalse(CALL_SESSION_ID)).willReturn(Optional.empty());

        assertThatThrownBy(() -> createService().getFeedbackTarget(member, CALL_SESSION_ID))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.CALL_SESSION_NOT_FOUND));
    }

    @Test
    void getFeedbackTarget_otherMembersCall_throwsCallSessionNotFound() {
        stubFound(callHistoryOf(memberOf(UUID.randomUUID()), CallStatus.ENDED));

        assertThatThrownBy(() -> createService().getFeedbackTarget(member, CALL_SESSION_ID))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.CALL_SESSION_NOT_FOUND));
    }

    @ParameterizedTest
    @EnumSource(value = CallStatus.class, names = {"PENDING", "IN_PROGRESS", "FAILED"})
    void getFeedbackTarget_notFeedbackableStatus_throwsCallNotFeedbackable(CallStatus status) {
        stubFound(callHistoryOf(member, status));

        assertThatThrownBy(() -> createService().getFeedbackTarget(member, CALL_SESSION_ID))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.CALL_NOT_FEEDBACKABLE));
    }

    @ParameterizedTest
    @EnumSource(value = CallStatus.class, names = {"ENDED", "EXPIRED"})
    void getFeedbackTarget_feedbackableStatus_returnsTargetWithCountAsIndex(CallStatus status) {
        stubFound(callHistoryOf(member, status));
        given(callHistoryRepository.countByMemberIdAndStatusNotAndStartedAtLessThanEqualAndDeletedFalse(
            memberId, CallStatus.FAILED, STARTED_AT)).willReturn(3L);

        FeedbackTargetCall target = createService().getFeedbackTarget(member, CALL_SESSION_ID);

        assertThat(target.callHistory().getId()).isEqualTo(callHistoryId);
        assertThat(target.callIndex()).isEqualTo(3);
    }

    @Test
    void getFeedbackTarget_neverUsesLockingLookup() {
        stubFound(callHistoryOf(member, CallStatus.ENDED));
        given(callHistoryRepository.countByMemberIdAndStatusNotAndStartedAtLessThanEqualAndDeletedFalse(
            memberId, CallStatus.FAILED, STARTED_AT)).willReturn(1L);

        createService().getFeedbackTarget(member, CALL_SESSION_ID);

        verify(callHistoryRepository, never()).findWithLockByCallSessionIdAndDeletedFalse(CALL_SESSION_ID);
    }

    @Test
    void findLatestFeedbackableCall_종료_만료_통화가_없으면_empty() {
        given(callHistoryRepository.findFirstByMemberIdAndStatusInAndDeletedFalseOrderByStartedAtDesc(
            any(), any())).willReturn(Optional.empty());

        assertThat(createService().findLatestFeedbackableCall(member)).isEmpty();
    }

    @Test
    void findLatestFeedbackableCall_있으면_세션과_순번을_돌려준다() {
        given(callHistoryRepository.findFirstByMemberIdAndStatusInAndDeletedFalseOrderByStartedAtDesc(
            any(), any())).willReturn(Optional.of(callHistoryOf(member, CallStatus.ENDED)));
        given(callHistoryRepository.countByMemberIdAndStatusNotAndStartedAtLessThanEqualAndDeletedFalse(
            memberId, CallStatus.FAILED, STARTED_AT)).willReturn(3L);

        LatestFeedbackableCall latest = createService().findLatestFeedbackableCall(member).orElseThrow();

        assertThat(latest).isEqualTo(new LatestFeedbackableCall(callHistoryId, CALL_SESSION_ID, 3));
    }

    @Test
    void findLatestFeedbackableCall_조회_상태는_ENDED와_EXPIRED만이다() {
        given(callHistoryRepository.findFirstByMemberIdAndStatusInAndDeletedFalseOrderByStartedAtDesc(
            any(), any())).willReturn(Optional.empty());

        createService().findLatestFeedbackableCall(member);

        @SuppressWarnings("unchecked")
        ArgumentCaptor<Collection<CallStatus>> captor = ArgumentCaptor.forClass(Collection.class);
        verify(callHistoryRepository).findFirstByMemberIdAndStatusInAndDeletedFalseOrderByStartedAtDesc(
            eq(memberId), captor.capture());
        assertThat(captor.getValue()).containsExactlyInAnyOrder(CallStatus.ENDED, CallStatus.EXPIRED);
    }

}
