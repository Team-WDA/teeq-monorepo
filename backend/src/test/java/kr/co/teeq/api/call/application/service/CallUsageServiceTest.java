package kr.co.teeq.api.call.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verifyNoInteractions;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.call.application.dto.response.CallUsageResponse;
import kr.co.teeq.api.call.core.constant.CallUsageUnit;
import kr.co.teeq.api.call.core.repository.CallHistoryRepository;
import kr.co.teeq.api.call.core.repository.CallHistoryRepository.CallUsageRow;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.repository.MemberRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class CallUsageServiceTest {

    private static final ZoneId KOREA = ZoneId.of("Asia/Seoul");

    private final UUID memberId = UUID.randomUUID();

    @Mock
    private CallHistoryRepository callHistoryRepository;

    @Mock
    private MemberRepository memberRepository;

    @Mock
    private Member member;

    private CallUsageService createService() {
        return new CallUsageService(callHistoryRepository, memberRepository, KOREA);
    }

    private static CallUsageRow row(String periodStart, long usedSeconds, long callCount) {
        return new CallUsageRow() {
            @Override
            public String getPeriodStart() {
                return periodStart;
            }

            @Override
            public long getUsedSeconds() {
                return usedSeconds;
            }

            @Override
            public long getCallCount() {
                return callCount;
            }
        };
    }

    private static Instant kstStart(String date) {
        return LocalDate.parse(date).atStartOfDay(KOREA).toInstant();
    }

    @Test
    void getUsages_day_fillsMissingDaysWithZeroInAscendingOrder() {
        given(callHistoryRepository.aggregateUsageOfAllMembers("day", "Asia/Seoul",
            kstStart("2026-10-01"), kstStart("2026-10-04")))
            .willReturn(List.of(row("2026-10-01", 600, 2), row("2026-10-03", 300, 1)));

        List<CallUsageResponse> responses = createService().getUsages(CallUsageUnit.DAY,
            LocalDate.of(2026, 10, 1), LocalDate.of(2026, 10, 3), null);

        assertThat(responses).containsExactly(
            new CallUsageResponse(LocalDate.of(2026, 10, 1), 600, 2),
            new CallUsageResponse(LocalDate.of(2026, 10, 2), 0, 0),
            new CallUsageResponse(LocalDate.of(2026, 10, 3), 300, 1));
    }

    @Test
    void getUsages_month_alignsToMonthBoundariesAndFillsZero() {
        given(callHistoryRepository.aggregateUsageOfAllMembers("month", "Asia/Seoul",
            kstStart("2026-08-01"), kstStart("2026-11-01")))
            .willReturn(List.of(row("2026-08-01", 900, 3), row("2026-10-01", 1200, 4)));

        List<CallUsageResponse> responses = createService().getUsages(CallUsageUnit.MONTH,
            LocalDate.of(2026, 8, 17), LocalDate.of(2026, 10, 2), null);

        assertThat(responses).containsExactly(
            new CallUsageResponse(LocalDate.of(2026, 8, 1), 900, 3),
            new CallUsageResponse(LocalDate.of(2026, 9, 1), 0, 0),
            new CallUsageResponse(LocalDate.of(2026, 10, 1), 1200, 4));
    }

    @Test
    void getUsages_withMemberId_usesMemberQuery() {
        given(memberRepository.findByIdAndDeletedFalse(memberId)).willReturn(Optional.of(member));
        given(callHistoryRepository.aggregateUsageOfMember(memberId, "day", "Asia/Seoul",
            kstStart("2026-10-01"), kstStart("2026-10-02")))
            .willReturn(List.of(row("2026-10-01", 100, 1)));

        List<CallUsageResponse> responses = createService().getUsages(CallUsageUnit.DAY,
            LocalDate.of(2026, 10, 1), LocalDate.of(2026, 10, 1), memberId);

        assertThat(responses).containsExactly(new CallUsageResponse(LocalDate.of(2026, 10, 1), 100, 1));
    }

    @Test
    void getUsages_unknownMember_throwsMemberNotFound() {
        given(memberRepository.findByIdAndDeletedFalse(memberId)).willReturn(Optional.empty());

        assertThatThrownBy(() -> createService().getUsages(CallUsageUnit.DAY,
            LocalDate.of(2026, 10, 1), LocalDate.of(2026, 10, 2), memberId))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.MEMBER_NOT_FOUND));
        verifyNoInteractions(callHistoryRepository);
    }

    @Test
    void getUsages_fromAfterTo_throwsInvalidRequest() {
        assertThatThrownBy(() -> createService().getUsages(CallUsageUnit.DAY,
            LocalDate.of(2026, 10, 2), LocalDate.of(2026, 10, 1), null))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.INVALID_REQUEST));
    }

    @Test
    void getUsages_dayRangeOf93DaysIsAllowedAnd94DaysIsRejected() {
        LocalDate from = LocalDate.of(2026, 7, 1);
        given(callHistoryRepository.aggregateUsageOfAllMembers("day", "Asia/Seoul",
            kstStart("2026-07-01"), kstStart("2026-10-02")))
            .willReturn(List.of());

        assertThat(createService().getUsages(CallUsageUnit.DAY, from, from.plusDays(92), null)).hasSize(93);
        assertThatThrownBy(() -> createService().getUsages(CallUsageUnit.DAY, from, from.plusDays(93), null))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.INVALID_REQUEST));
    }

    @Test
    void getUsages_monthRangeOf24MonthsIsAllowedAnd25MonthsIsRejected() {
        given(callHistoryRepository.aggregateUsageOfAllMembers("month", "Asia/Seoul",
            kstStart("2025-01-01"), kstStart("2027-01-01")))
            .willReturn(List.of());

        assertThat(createService().getUsages(CallUsageUnit.MONTH,
            LocalDate.of(2025, 1, 31), LocalDate.of(2026, 12, 1), null)).hasSize(24);
        assertThatThrownBy(() -> createService().getUsages(CallUsageUnit.MONTH,
            LocalDate.of(2025, 1, 31), LocalDate.of(2027, 1, 1), null))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.INVALID_REQUEST));
    }

}
