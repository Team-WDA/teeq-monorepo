package kr.co.teeq.api.call.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verify;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import kr.co.teeq.api.call.application.dto.request.CallHistorySearchRequest;
import kr.co.teeq.api.call.application.dto.response.CallHistoryItemResponse;
import kr.co.teeq.api.call.application.dto.response.MemberCallSummaryResponse;
import kr.co.teeq.api.call.core.constant.CallStatus;
import kr.co.teeq.api.call.core.constant.LimitKind;
import kr.co.teeq.api.call.core.entity.CallHistory;
import kr.co.teeq.api.call.core.repository.CallHistoryRepository;
import kr.co.teeq.api.call.core.repository.CallHistoryRepository.MemberCallSummaryRow;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.repository.MemberRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class CallHistoryQueryServiceTest {

    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final ZoneId KOREA = ZoneId.of("Asia/Seoul");
    private static final Clock CLOCK = Clock.fixed(Instant.parse("2026-10-20T03:00:00Z"), ZoneOffset.UTC);

    @Mock
    private CallHistoryRepository callHistoryRepository;

    @Mock
    private MemberRepository memberRepository;

    private CallHistoryQueryService callHistoryQueryService;

    @BeforeEach
    void setUp() {
        callHistoryQueryService = new CallHistoryQueryService(callHistoryRepository, memberRepository, CLOCK, KOREA);
    }

    private Member member() {
        Member member = Member.createMember(LoginType.GOOGLE, "google-uid", "soyeon@teeq.com", "소연");
        ReflectionTestUtils.setField(member, "id", MEMBER_ID);
        return member;
    }

    @Test
    void getMemberSummary_usesExcludedStatusesAndRecentSevenDayStart() {
        given(memberRepository.findByIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.of(member()));
        MemberCallSummaryRow row = new MemberCallSummaryRow() {
            public long getCallCount() { return 3; }
            public long getUsedSeconds() { return 120; }
            public Instant getLastStartedAt() { return Instant.parse("2026-10-19T01:00:00Z"); }
            public long getRecentCallCount() { return 2; }
        };
        given(callHistoryRepository.summarizeByMember(any(), any(), any())).willReturn(row);

        MemberCallSummaryResponse response = callHistoryQueryService.getMemberSummary(MEMBER_ID);

        verify(callHistoryRepository).summarizeByMember(MEMBER_ID, Set.of(CallStatus.FAILED, CallStatus.PENDING, CallStatus.CANCELLED),
            Instant.parse("2026-10-13T15:00:00Z"));
        assertThat(response).isEqualTo(new MemberCallSummaryResponse(3, 120,
            Instant.parse("2026-10-19T01:00:00Z"), 2));
    }

    @Test
    void getMemberSummary_unknownMember_throwsMemberNotFound() {
        given(memberRepository.findByIdAndDeletedFalse(MEMBER_ID)).willReturn(Optional.empty());

        assertThatThrownBy(() -> callHistoryQueryService.getMemberSummary(MEMBER_ID))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.MEMBER_NOT_FOUND));
    }

    @Test
    void toInstantRange_convertsInclusiveDatesInKorea() {
        Instant[] range = CallHistoryQueryService.toInstantRange(
            LocalDate.of(2026, 10, 1), LocalDate.of(2026, 10, 3), KOREA);

        assertThat(range[0]).isEqualTo(Instant.parse("2026-09-30T15:00:00Z"));
        assertThat(range[1]).isEqualTo(Instant.parse("2026-10-03T15:00:00Z"));
    }

    @Test
    void toInstantRange_nullDates_stayNull() {
        Instant[] range = CallHistoryQueryService.toInstantRange(null, null, KOREA);

        assertThat(range).containsExactly(null, null);
    }

    @Test
    void search_fromAfterTo_throwsInvalidRequest() {
        CallHistorySearchRequest request = new CallHistorySearchRequest(
            null, null, LocalDate.of(2026, 10, 5), LocalDate.of(2026, 10, 1), null, false);

        assertThatThrownBy(() -> callHistoryQueryService.search(request, PageRequest.of(0, 20)))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.INVALID_REQUEST));
    }

    @Test
    @SuppressWarnings("unchecked")
    void search_fixesSortToStartedAtDescendingThenIdDescending() {
        given(callHistoryRepository.findAll(any(Specification.class), any(org.springframework.data.domain.Pageable.class)))
            .willReturn(org.springframework.data.domain.Page.empty());

        callHistoryQueryService.search(new CallHistorySearchRequest(null, " ", null, null, null, false),
            PageRequest.of(1, 20, Sort.by("memberId")));

        ArgumentCaptor<org.springframework.data.domain.Pageable> captor =
            ArgumentCaptor.forClass(org.springframework.data.domain.Pageable.class);
        verify(callHistoryRepository).findAll(any(Specification.class), captor.capture());
        assertThat(captor.getValue().getPageNumber()).isEqualTo(1);
        assertThat(captor.getValue().getPageSize()).isEqualTo(20);
        assertThat(captor.getValue().getSort())
            .isEqualTo(Sort.by(Sort.Order.desc("startedAt"), Sort.Order.desc("id")));
    }

    @Test
    void getBySessionId_unknown_throwsCallSessionNotFound() {
        given(callHistoryRepository.findByCallSessionIdAndDeletedFalse("session")).willReturn(Optional.empty());

        assertThatThrownBy(() -> callHistoryQueryService.getBySessionId("session"))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.CALL_SESSION_NOT_FOUND));
    }

    @Test
    void getBySessionId_deletedMember_throwsCallSessionNotFound() {
        Member member = member();
        ReflectionTestUtils.setField(member, "deleted", true);
        given(callHistoryRepository.findByCallSessionIdAndDeletedFalse("session"))
            .willReturn(Optional.of(callHistory(member)));

        assertThatThrownBy(() -> callHistoryQueryService.getBySessionId("session"))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.CALL_SESSION_NOT_FOUND));
    }

    @Test
    void getBySessionId_found_mapsItem() {
        CallHistory callHistory = callHistory(member());
        given(callHistoryRepository.findByCallSessionIdAndDeletedFalse("session"))
            .willReturn(Optional.of(callHistory));

        CallHistoryItemResponse response = callHistoryQueryService.getBySessionId("session");

        assertThat(response.callSessionId()).isEqualTo("session");
        assertThat(response.memberId()).isEqualTo(MEMBER_ID);
        assertThat(response.memberNickname()).isEqualTo("소연");
        assertThat(response.memberEmail()).isEqualTo("soyeon@teeq.com");
        assertThat(response.status()).isEqualTo(CallStatus.IN_PROGRESS);
        assertThat(response.llmModel()).isEqualTo("model-x");
    }

    private CallHistory callHistory(Member member) {
        CallHistory callHistory = CallHistory.pending(member, "persona", LimitKind.PER_DAY,
            Instant.parse("2026-10-19T01:00:00Z"));
        callHistory.activate("session", "prompt-v1", "model-x");
        return callHistory;
    }

}
