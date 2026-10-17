package kr.teeq.api.call.application.service;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import kr.teeq.api.call.application.dto.response.CallUsageResponse;
import kr.teeq.api.call.core.constant.CallUsageUnit;
import kr.teeq.api.call.core.repository.CallHistoryRepository;
import kr.teeq.api.call.core.repository.CallHistoryRepository.CallUsageRow;
import kr.teeq.api.common.core.exception.CustomException;
import kr.teeq.api.common.core.exception.ErrorCode;
import kr.teeq.api.member.core.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class CallUsageService {

    private static final long MAX_DAYS = 93;
    private static final long MAX_MONTHS = 24;

    private final CallHistoryRepository callHistoryRepository;
    private final MemberRepository memberRepository;
    private final ZoneId koreaZoneId;

    // memberId가 없으면 서비스 전체 사용량이다. 통화가 없는 기간도 0으로 채워 오름차순으로 돌려준다
    @Transactional(readOnly = true)
    public List<CallUsageResponse> getUsages(CallUsageUnit unit, LocalDate from, LocalDate to, UUID memberId) {
        if (from.isAfter(to)) {
            throw new CustomException(ErrorCode.INVALID_REQUEST);
        }
        // 월별은 from, to가 속한 달 전체를 조회 범위로 삼는다
        LocalDate firstPeriodStart = unit.alignToPeriodStart(from);
        LocalDate lastPeriodStart = unit.alignToPeriodStart(to);
        validateRange(unit, firstPeriodStart, lastPeriodStart);
        if (memberId != null) {
            memberRepository.findByIdAndDeletedFalse(memberId)
                .orElseThrow(() -> new CustomException(ErrorCode.MEMBER_NOT_FOUND));
        }

        Instant fromInclusive = firstPeriodStart.atStartOfDay(koreaZoneId).toInstant();
        Instant toExclusive = unit.nextPeriodStart(lastPeriodStart).atStartOfDay(koreaZoneId).toInstant();
        List<CallUsageRow> rows = memberId == null
            ? callHistoryRepository.aggregateUsageOfAllMembers(
                unit.truncateField(), koreaZoneId.getId(), fromInclusive, toExclusive)
            : callHistoryRepository.aggregateUsageOfMember(
                memberId, unit.truncateField(), koreaZoneId.getId(), fromInclusive, toExclusive);

        Map<LocalDate, CallUsageRow> rowByPeriodStart = new HashMap<>();
        for (CallUsageRow row : rows) {
            rowByPeriodStart.put(LocalDate.parse(row.getPeriodStart()), row);
        }

        List<CallUsageResponse> responses = new ArrayList<>();
        for (LocalDate periodStart = firstPeriodStart; !periodStart.isAfter(lastPeriodStart);
            periodStart = unit.nextPeriodStart(periodStart)) {
            CallUsageRow row = rowByPeriodStart.get(periodStart);
            responses.add(row == null
                ? new CallUsageResponse(periodStart, 0, 0)
                : new CallUsageResponse(periodStart, row.getUsedSeconds(), row.getCallCount()));
        }
        return responses;
    }

    // 양 끝 기간을 포함한 기간 수가 단위별 최대치를 넘으면 거부한다
    private void validateRange(CallUsageUnit unit, LocalDate firstPeriodStart, LocalDate lastPeriodStart) {
        long periodCount = unit == CallUsageUnit.MONTH
            ? ChronoUnit.MONTHS.between(firstPeriodStart, lastPeriodStart) + 1
            : ChronoUnit.DAYS.between(firstPeriodStart, lastPeriodStart) + 1;
        long maxPeriodCount = unit == CallUsageUnit.MONTH ? MAX_MONTHS : MAX_DAYS;
        if (periodCount > maxPeriodCount) {
            throw new CustomException(ErrorCode.INVALID_REQUEST);
        }
    }

}
