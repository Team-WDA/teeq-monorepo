package kr.teeq.api.call.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import kr.teeq.api.call.application.dto.request.CallHistoryRecordRequest;
import kr.teeq.api.call.application.dto.response.CallHistoryRecordResult;
import kr.teeq.api.call.core.entity.CallHistory;
import kr.teeq.api.call.core.repository.CallHistoryRepository;
import kr.teeq.api.common.core.exception.CustomException;
import kr.teeq.api.common.core.exception.ErrorCode;
import kr.teeq.api.member.core.entity.Member;
import kr.teeq.api.member.core.repository.MemberRepository;
import kr.teeq.api.setting.application.service.SettingConfigService;
import kr.teeq.api.setting.core.constant.SettingKey;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;

@ExtendWith(MockitoExtension.class)
class CallHistoryServiceTest {

    private static final String CALL_SESSION_ID = "session-1";
    private static final Instant STARTED_AT = Instant.parse("2026-10-16T03:00:00Z");

    private final UUID memberId = UUID.randomUUID();

    @Mock
    private CallHistoryRepository callHistoryRepository;

    @Mock
    private MemberRepository memberRepository;

    @Mock
    private SettingConfigService settingConfigService;

    @Mock
    private Member member;

    private CallHistoryService createService() {
        return new CallHistoryService(callHistoryRepository, memberRepository, settingConfigService);
    }

    private CallHistoryRecordRequest request(int durationSeconds) {
        return new CallHistoryRecordRequest(CALL_SESSION_ID, memberId, STARTED_AT, durationSeconds);
    }

    private CallHistory existingHistory() {
        return CallHistory.builder()
            .memberId(UUID.randomUUID())
            .callSessionId(CALL_SESSION_ID)
            .startedAt(Instant.parse("2026-10-15T03:00:00Z"))
            .durationSeconds(77)
            .build();
    }

    private void stubMemberExists() {
        given(memberRepository.findByIdAndDeletedFalse(memberId)).willReturn(Optional.of(member));
    }

    private void stubPerSessionLimit() {
        given(settingConfigService.getInt(SettingKey.CALL_MAX_SECONDS_PER_SESSION)).willReturn(1200L);
    }

    private void stubSaveReturnsArgument() {
        given(callHistoryRepository.saveAndFlush(any(CallHistory.class)))
            .willAnswer(invocation -> invocation.getArgument(0));
    }

    private CallHistory captureSavedHistory() {
        ArgumentCaptor<CallHistory> captor = ArgumentCaptor.forClass(CallHistory.class);
        verify(callHistoryRepository).saveAndFlush(captor.capture());
        return captor.getValue();
    }

    @Test
    void record_newSession_savesAndReturnsCreated() {
        stubMemberExists();
        stubPerSessionLimit();
        stubSaveReturnsArgument();
        given(callHistoryRepository.findByCallSessionIdAndDeletedFalse(CALL_SESSION_ID)).willReturn(Optional.empty());

        CallHistoryRecordResult result = createService().record(request(300));

        CallHistory saved = captureSavedHistory();
        assertThat(saved.getMemberId()).isEqualTo(memberId);
        assertThat(saved.getCallSessionId()).isEqualTo(CALL_SESSION_ID);
        assertThat(saved.getStartedAt()).isEqualTo(STARTED_AT);
        assertThat(saved.getDurationSeconds()).isEqualTo(300);
        assertThat(result.created()).isTrue();
        assertThat(result.history().durationSeconds()).isEqualTo(300);
    }

    @Test
    void record_durationZero_isRecorded() {
        stubMemberExists();
        stubPerSessionLimit();
        stubSaveReturnsArgument();
        given(callHistoryRepository.findByCallSessionIdAndDeletedFalse(CALL_SESSION_ID)).willReturn(Optional.empty());

        CallHistoryRecordResult result = createService().record(request(0));

        assertThat(captureSavedHistory().getDurationSeconds()).isZero();
        assertThat(result.created()).isTrue();
    }

    @Test
    void record_durationAbovePerSessionLimit_isCappedTo1200() {
        stubMemberExists();
        stubPerSessionLimit();
        stubSaveReturnsArgument();
        given(callHistoryRepository.findByCallSessionIdAndDeletedFalse(CALL_SESSION_ID)).willReturn(Optional.empty());

        CallHistoryRecordResult result = createService().record(request(1500));

        assertThat(captureSavedHistory().getDurationSeconds()).isEqualTo(1200);
        assertThat(result.history().durationSeconds()).isEqualTo(1200);
    }

    @Test
    void record_existingSession_returnsStoredValuesWithoutSaving() {
        CallHistory existing = existingHistory();
        stubMemberExists();
        given(callHistoryRepository.findByCallSessionIdAndDeletedFalse(CALL_SESSION_ID))
            .willReturn(Optional.of(existing));

        CallHistoryRecordResult result = createService().record(request(300));

        verify(callHistoryRepository, never()).saveAndFlush(any());
        assertThat(result.created()).isFalse();
        assertThat(result.history().memberId()).isEqualTo(existing.getMemberId());
        assertThat(result.history().startedAt()).isEqualTo(existing.getStartedAt());
        assertThat(result.history().durationSeconds()).isEqualTo(77);
    }

    @Test
    void record_concurrentDuplicate_fallsBackToExisting() {
        CallHistory existing = existingHistory();
        stubMemberExists();
        stubPerSessionLimit();
        given(callHistoryRepository.findByCallSessionIdAndDeletedFalse(CALL_SESSION_ID))
            .willReturn(Optional.empty())
            .willReturn(Optional.of(existing));
        given(callHistoryRepository.saveAndFlush(any(CallHistory.class)))
            .willThrow(new DataIntegrityViolationException("uq_call_history_session_active"));

        CallHistoryRecordResult result = createService().record(request(300));

        assertThat(result.created()).isFalse();
        assertThat(result.history().durationSeconds()).isEqualTo(77);
    }

    @Test
    void record_otherIntegrityViolation_rethrows() {
        DataIntegrityViolationException violation = new DataIntegrityViolationException("fk_call_history_member");
        stubMemberExists();
        stubPerSessionLimit();
        given(callHistoryRepository.findByCallSessionIdAndDeletedFalse(CALL_SESSION_ID)).willReturn(Optional.empty());
        given(callHistoryRepository.saveAndFlush(any(CallHistory.class))).willThrow(violation);

        assertThatThrownBy(() -> createService().record(request(300))).isSameAs(violation);
    }

    @Test
    void record_unknownMember_throwsMemberNotFound() {
        given(memberRepository.findByIdAndDeletedFalse(memberId)).willReturn(Optional.empty());

        assertThatThrownBy(() -> createService().record(request(300)))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.MEMBER_NOT_FOUND));
    }

}
