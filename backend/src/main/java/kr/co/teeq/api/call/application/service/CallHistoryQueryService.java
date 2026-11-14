package kr.co.teeq.api.call.application.service;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import kr.co.teeq.api.call.application.dto.request.CallHistorySearchRequest;
import kr.co.teeq.api.call.application.dto.response.CallHistoryItemResponse;
import kr.co.teeq.api.call.application.dto.response.CallHistoryPageResponse;
import kr.co.teeq.api.call.application.dto.response.MemberCallSummaryResponse;
import kr.co.teeq.api.call.core.constant.CallStatus;
import kr.co.teeq.api.call.core.entity.CallHistory;
import kr.co.teeq.api.call.core.repository.CallHistoryRepository;
import kr.co.teeq.api.call.core.repository.CallHistoryRepository.MemberCallSummaryRow;
import kr.co.teeq.api.call.core.repository.CallHistorySpecifications;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 관리자용 통화 목록 검색, 회원 통화 요약, 통화 세션 조회.
 */
@Service
@RequiredArgsConstructor
public class CallHistoryQueryService {

    // 요청의 정렬은 무시하고 항상 최근 시작 통화가 먼저 오게 한다
    private static final Sort CALL_SORT = Sort.by(Sort.Order.desc("startedAt"), Sort.Order.desc("id"));
    // 요약의 통화 횟수·사용 시간에서 제외하는 상태
    private static final Set<CallStatus> SUMMARY_EXCLUDED_STATUSES = Set.of(CallStatus.FAILED, CallStatus.PENDING,
        CallStatus.CANCELLED);
    // 오늘을 포함한 최근 일수
    private static final long RECENT_DAYS = 7;

    private final CallHistoryRepository callHistoryRepository;
    private final MemberRepository memberRepository;
    private final Clock clock;
    private final ZoneId koreaZoneId;

    @Transactional(readOnly = true)
    public CallHistoryPageResponse search(CallHistorySearchRequest request, Pageable pageable) {
        if (request.from() != null && request.to() != null && request.from().isAfter(request.to())) {
            throw new CustomException(ErrorCode.INVALID_REQUEST);
        }
        Pageable fixedSortPageable = PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(), CALL_SORT);
        Page<CallHistory> page = callHistoryRepository.findAll(toSpecification(request), fixedSortPageable);
        List<CallHistoryItemResponse> content = page.getContent().stream().map(this::toItemResponse).toList();
        return new CallHistoryPageResponse(content, page.getNumber(), page.getSize(), page.getTotalElements());
    }

    @Transactional(readOnly = true)
    public MemberCallSummaryResponse getMemberSummary(UUID memberId) {
        memberRepository.findByIdAndDeletedFalse(memberId)
            .orElseThrow(() -> new CustomException(ErrorCode.MEMBER_NOT_FOUND));
        Instant recentFromInclusive = LocalDate.now(clock.withZone(koreaZoneId))
            .minusDays(RECENT_DAYS - 1).atStartOfDay(koreaZoneId).toInstant();
        MemberCallSummaryRow row = callHistoryRepository.summarizeByMember(
            memberId, SUMMARY_EXCLUDED_STATUSES, recentFromInclusive);
        return new MemberCallSummaryResponse(
            row.getCallCount(), row.getUsedSeconds(), row.getLastStartedAt(), row.getRecentCallCount());
    }

    @Transactional(readOnly = true)
    public CallHistoryItemResponse getBySessionId(String callSessionId) {
        CallHistory callHistory = callHistoryRepository.findByCallSessionIdAndDeletedFalse(callSessionId)
            .orElseThrow(() -> new CustomException(ErrorCode.CALL_SESSION_NOT_FOUND));
        if (callHistory.getMember().isDeleted()) {
            throw new CustomException(ErrorCode.CALL_SESSION_NOT_FOUND);
        }
        return toItemResponse(callHistory);
    }

    // 포함 날짜 구간 [from, to]를 한국 시간 기준 [from 00:00, to+1일 00:00) 시각 구간으로 바꾼다. null은 그대로 둔다
    static Instant[] toInstantRange(LocalDate from, LocalDate to, ZoneId zoneId) {
        Instant fromInclusive = from == null ? null : from.atStartOfDay(zoneId).toInstant();
        Instant toExclusive = to == null ? null : to.plusDays(1).atStartOfDay(zoneId).toInstant();
        return new Instant[] {fromInclusive, toExclusive};
    }

    private Specification<CallHistory> toSpecification(CallHistorySearchRequest request) {
        List<Specification<CallHistory>> specifications = new ArrayList<>();
        specifications.add(CallHistorySpecifications.notDeleted());
        specifications.add(CallHistorySpecifications.ofActiveMemberOnly());
        if (request.memberId() != null) {
            specifications.add(CallHistorySpecifications.ofMember(request.memberId()));
        }
        if (request.keyword() != null && !request.keyword().isBlank()) {
            specifications.add(CallHistorySpecifications.memberKeywordContaining(request.keyword().trim()));
        }
        Instant[] range = toInstantRange(request.from(), request.to(), koreaZoneId);
        if (range[0] != null || range[1] != null) {
            specifications.add(CallHistorySpecifications.startedBetween(range[0], range[1]));
        }
        if (request.status() != null) {
            specifications.add(CallHistorySpecifications.ofStatus(request.status()));
        }
        if (request.abnormalOnly()) {
            specifications.add(CallHistorySpecifications.abnormalOnly());
        }
        return Specification.allOf(specifications);
    }

    private CallHistoryItemResponse toItemResponse(CallHistory callHistory) {
        Member member = callHistory.getMember();
        return new CallHistoryItemResponse(callHistory.getCallSessionId(), member.getId(), member.getNickname(),
            member.getEmail(), callHistory.getStartedAt(), callHistory.getDurationSeconds(), callHistory.getStatus(),
            callHistory.getEndReason(), callHistory.getLlmModel());
    }

}
