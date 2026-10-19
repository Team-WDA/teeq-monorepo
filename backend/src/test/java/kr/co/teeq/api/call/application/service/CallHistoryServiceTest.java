package kr.co.teeq.api.call.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.verify;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import kr.co.teeq.api.call.application.dto.request.CallUsageReportRequest;
import kr.co.teeq.api.call.application.dto.response.CallHistoryResponse;
import kr.co.teeq.api.call.core.constant.CallStatus;
import kr.co.teeq.api.call.core.entity.CallHistory;
import kr.co.teeq.api.call.core.repository.CallHistoryRepository;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.setting.application.service.SettingConfigService;
import kr.co.teeq.api.setting.core.constant.SettingKey;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InOrder;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;

@ExtendWith(MockitoExtension.class)
class CallHistoryServiceTest {

    private static final Instant NOW = Instant.parse("2026-10-16T03:00:00Z");
    private static final long MAX_SECONDS_PER_SESSION = 1200L;
    private static final Instant EXPIRY_CUTOFF = NOW.minusSeconds(MAX_SECONDS_PER_SESSION);
    private static final Set<CallStatus> ACTIVE_STATUSES = Set.of(CallStatus.PENDING, CallStatus.IN_PROGRESS);

    private final UUID memberId = UUID.randomUUID();

    @Mock
    private Member member;

    @Mock
    private CallHistoryRepository callHistoryRepository;

    @Mock
    private SettingConfigService settingConfigService;

    private CallHistoryService createService() {
        return new CallHistoryService(callHistoryRepository, settingConfigService, Clock.fixed(NOW, ZoneOffset.UTC));
    }

    private void stubMaxSecondsPerSession() {
        given(settingConfigService.getInt(SettingKey.CALL_MAX_SECONDS_PER_SESSION)).willReturn(MAX_SECONDS_PER_SESSION);
    }

    private void stubExpiryCandidates(List<CallHistory> candidates) {
        given(member.getId()).willReturn(memberId);
        given(callHistoryRepository.findByMemberIdAndStatusInAndStartedAtLessThanEqualAndDeletedFalse(
            memberId, ACTIVE_STATUSES, EXPIRY_CUTOFF)).willReturn(candidates);
    }

    @Test
    void startPending_expiredCandidate_expiresAndFlushesBeforeInsert() {
        stubMaxSecondsPerSession();
        CallHistory expiredCandidate = CallHistory.pending(member, EXPIRY_CUTOFF);
        stubExpiryCandidates(List.of(expiredCandidate));
        given(callHistoryRepository.saveAndFlush(any(CallHistory.class))).willAnswer(call -> call.getArgument(0));

        createService().startPending(member);

        assertThat(expiredCandidate.getStatus()).isEqualTo(CallStatus.EXPIRED);
        // UPDATE가 INSERT보다 먼저 나가야 partial unique index에 걸리지 않는다
        InOrder inOrder = inOrder(callHistoryRepository);
        inOrder.verify(callHistoryRepository).flush();
        inOrder.verify(callHistoryRepository).saveAndFlush(any(CallHistory.class));
    }

    @Test
    void startPending_queriesCandidatesWithInclusiveCutoff() {
        stubMaxSecondsPerSession();
        stubExpiryCandidates(List.of());
        given(callHistoryRepository.saveAndFlush(any(CallHistory.class))).willAnswer(call -> call.getArgument(0));

        createService().startPending(member);

        // startedAt + 1회 한도 == 지금이면 startedAt == 지금 - 한도 이므로 cutoff 이하(포함)에 걸린다
        verify(callHistoryRepository).findByMemberIdAndStatusInAndStartedAtLessThanEqualAndDeletedFalse(
            memberId, ACTIVE_STATUSES, EXPIRY_CUTOFF);
    }

    @Test
    void startPending_savesPendingRecordWithCurrentTime() {
        stubMaxSecondsPerSession();
        stubExpiryCandidates(List.of());
        given(callHistoryRepository.saveAndFlush(any(CallHistory.class))).willAnswer(call -> call.getArgument(0));

        createService().startPending(member);

        verify(callHistoryRepository).saveAndFlush(org.mockito.ArgumentMatchers.argThat(saved ->
            saved.getMember() == member
                && saved.getStartedAt().equals(NOW)
                && saved.getStatus() == CallStatus.PENDING));
    }

    @Test
    void startPending_concurrentActiveRecord_throwsCallAlreadyInProgress() {
        stubMaxSecondsPerSession();
        stubExpiryCandidates(List.of());
        given(callHistoryRepository.saveAndFlush(any(CallHistory.class)))
            .willThrow(new DataIntegrityViolationException("unique"));

        assertThatThrownBy(() -> createService().startPending(member))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.CALL_ALREADY_IN_PROGRESS));
    }

    @Test
    void activate_pendingRecord_becomesInProgressWithSessionId() {
        UUID callHistoryId = UUID.randomUUID();
        CallHistory callHistory = CallHistory.pending(member, NOW);
        given(callHistoryRepository.findByIdAndDeletedFalse(callHistoryId)).willReturn(Optional.of(callHistory));

        createService().activate(callHistoryId, "call-session-1");

        assertThat(callHistory.getStatus()).isEqualTo(CallStatus.IN_PROGRESS);
        assertThat(callHistory.getCallSessionId()).isEqualTo("call-session-1");
    }

    @Test
    void activate_missingRecord_throwsResourceNotFound() {
        UUID callHistoryId = UUID.randomUUID();
        given(callHistoryRepository.findByIdAndDeletedFalse(callHistoryId)).willReturn(Optional.empty());

        assertThatThrownBy(() -> createService().activate(callHistoryId, "call-session-1"))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.RESOURCE_NOT_FOUND));
    }

    @Test
    void fail_pendingRecord_becomesFailed() {
        UUID callHistoryId = UUID.randomUUID();
        CallHistory callHistory = CallHistory.pending(member, NOW);
        given(callHistoryRepository.findByIdAndDeletedFalse(callHistoryId)).willReturn(Optional.of(callHistory));

        createService().fail(callHistoryId);

        assertThat(callHistory.getStatus()).isEqualTo(CallStatus.FAILED);
    }

    @Test
    void fail_missingRecord_throwsResourceNotFoundWithoutSaving() {
        UUID callHistoryId = UUID.randomUUID();
        given(callHistoryRepository.findByIdAndDeletedFalse(callHistoryId)).willReturn(Optional.empty());

        assertThatThrownBy(() -> createService().fail(callHistoryId))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.RESOURCE_NOT_FOUND));
    }

    private static final Instant REPORTED_ENDED_AT = Instant.parse("2026-10-16T03:05:00Z");

    private CallHistory inProgressRecord() {
        CallHistory callHistory = CallHistory.pending(member, NOW.minusSeconds(300));
        callHistory.activate("call-session-1");
        return callHistory;
    }

    private void stubLockedRecord(CallHistory callHistory) {
        given(callHistoryRepository.findWithLockByCallSessionIdAndDeletedFalse("call-session-1"))
            .willReturn(Optional.of(callHistory));
    }

    @Test
    void reportUsage_inProgressRecord_becomesEndedWithUsedSecondsAndEndedAt() {
        stubMaxSecondsPerSession();
        CallHistory callHistory = inProgressRecord();
        stubLockedRecord(callHistory);

        CallHistoryResponse response = createService()
            .reportUsage("call-session-1", new CallUsageReportRequest(300, REPORTED_ENDED_AT));

        assertThat(callHistory.getStatus()).isEqualTo(CallStatus.ENDED);
        assertThat(callHistory.getDurationSeconds()).isEqualTo(300);
        assertThat(callHistory.getEndedAt()).isEqualTo(REPORTED_ENDED_AT);
        assertThat(response.status()).isEqualTo(CallStatus.ENDED);
        assertThat(response.durationSeconds()).isEqualTo(300);
    }

    @Test
    void reportUsage_alreadyEndedRecord_keepsFirstReportedValues() {
        CallHistory callHistory = inProgressRecord();
        callHistory.end(300, REPORTED_ENDED_AT);
        stubLockedRecord(callHistory);

        CallHistoryResponse response = createService()
            .reportUsage("call-session-1", new CallUsageReportRequest(900, REPORTED_ENDED_AT.plusSeconds(60)));

        assertThat(callHistory.getDurationSeconds()).isEqualTo(300);
        assertThat(callHistory.getEndedAt()).isEqualTo(REPORTED_ENDED_AT);
        assertThat(response.durationSeconds()).isEqualTo(300);
        assertThat(response.status()).isEqualTo(CallStatus.ENDED);
    }

    @Test
    void reportUsage_expiredRecord_isOverwrittenByLateReport() {
        stubMaxSecondsPerSession();
        CallHistory callHistory = inProgressRecord();
        callHistory.expire();
        stubLockedRecord(callHistory);

        CallHistoryResponse response = createService()
            .reportUsage("call-session-1", new CallUsageReportRequest(450, REPORTED_ENDED_AT));

        assertThat(callHistory.getStatus()).isEqualTo(CallStatus.ENDED);
        assertThat(callHistory.getDurationSeconds()).isEqualTo(450);
        assertThat(response.durationSeconds()).isEqualTo(450);
    }

    @Test
    void reportUsage_overMaxSecondsPerSession_isCappedToLimit() {
        stubMaxSecondsPerSession();
        CallHistory callHistory = inProgressRecord();
        stubLockedRecord(callHistory);

        createService().reportUsage("call-session-1",
            new CallUsageReportRequest((int) MAX_SECONDS_PER_SESSION + 500, REPORTED_ENDED_AT));

        assertThat(callHistory.getDurationSeconds()).isEqualTo((int) MAX_SECONDS_PER_SESSION);
    }

    @Test
    void reportUsage_unknownSession_throwsCallSessionNotFound() {
        given(callHistoryRepository.findWithLockByCallSessionIdAndDeletedFalse("unknown"))
            .willReturn(Optional.empty());

        assertThatThrownBy(() -> createService()
            .reportUsage("unknown", new CallUsageReportRequest(300, REPORTED_ENDED_AT)))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.CALL_SESSION_NOT_FOUND));
    }

}
