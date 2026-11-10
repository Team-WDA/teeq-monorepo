package kr.co.teeq.api.feedback.application.service;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import kr.co.teeq.api.call.core.entity.CallHistory;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.feedback.application.dto.request.FeedbackSearchRequest;
import kr.co.teeq.api.feedback.application.dto.response.CallFeedbackResponse;
import kr.co.teeq.api.feedback.application.dto.response.CallFeedbackResponse.DetailedPart;
import kr.co.teeq.api.feedback.application.dto.response.CallFeedbackResponse.RequiredPart;
import kr.co.teeq.api.feedback.application.dto.response.FeedbackListItemResponse;
import kr.co.teeq.api.feedback.application.dto.response.FeedbackPageResponse;
import kr.co.teeq.api.feedback.core.constant.AwkwardMoment;
import kr.co.teeq.api.feedback.core.constant.StartReason;
import kr.co.teeq.api.feedback.core.entity.DetailedFeedback;
import kr.co.teeq.api.feedback.core.entity.DetailedFeedbackStartReason;
import kr.co.teeq.api.feedback.core.entity.RequiredFeedback;
import kr.co.teeq.api.feedback.core.entity.RequiredFeedbackAwkwardMoment;
import kr.co.teeq.api.feedback.core.repository.DetailedFeedbackRepository;
import kr.co.teeq.api.feedback.core.repository.DetailedFeedbackStartReasonRepository;
import kr.co.teeq.api.feedback.core.repository.FeedbackSpecifications;
import kr.co.teeq.api.feedback.core.repository.RequiredFeedbackAwkwardMomentRepository;
import kr.co.teeq.api.feedback.core.repository.RequiredFeedbackRepository;
import kr.co.teeq.api.member.core.entity.Member;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 관리자용 피드백 조회. 목록은 필수 피드백 기준으로 통화 하나가 한 행이고, 통화 상세에는 필수·상세 피드백 전체를 보인다.
 * 탈퇴 회원의 피드백은 회원 삭제 때 소프트 삭제되므로 삭제 여부(deleted = false)만으로 걸러진다.
 */
@Service
@RequiredArgsConstructor
public class FeedbackQueryService {

    // 요청의 정렬은 무시하고 항상 최근 제출이 먼저 오게 한다
    private static final Sort FEEDBACK_SORT = Sort.by(Sort.Order.desc("createdAt"), Sort.Order.desc("id"));

    private final RequiredFeedbackRepository requiredFeedbackRepository;
    private final RequiredFeedbackAwkwardMomentRepository requiredFeedbackAwkwardMomentRepository;
    private final DetailedFeedbackRepository detailedFeedbackRepository;
    private final DetailedFeedbackStartReasonRepository detailedFeedbackStartReasonRepository;
    private final ZoneId koreaZoneId;

    @Transactional(readOnly = true)
    public FeedbackPageResponse search(FeedbackSearchRequest request, Pageable pageable) {
        if (request.from() != null && request.to() != null && request.from().isAfter(request.to())) {
            throw new CustomException(ErrorCode.INVALID_REQUEST);
        }
        Pageable fixedSortPageable = PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(), FEEDBACK_SORT);
        Page<RequiredFeedback> page = requiredFeedbackRepository.findAll(toSpecification(request), fixedSortPageable);
        if (page.isEmpty()) {
            return new FeedbackPageResponse(List.of(), page.getNumber(), page.getSize(), page.getTotalElements());
        }
        Set<UUID> detailedCallHistoryIds = detailedCallHistoryIds(page.getContent());
        List<FeedbackListItemResponse> items = page.getContent().stream()
            .map(feedback -> toListItem(feedback,
                detailedCallHistoryIds.contains(feedback.getCallHistory().getId())))
            .toList();
        return new FeedbackPageResponse(items, page.getNumber(), page.getSize(), page.getTotalElements());
    }

    // 필수 피드백이 없으면 상세 피드백도 없다(상세는 필수 제출 뒤에만 받는다)
    @Transactional(readOnly = true)
    public Optional<CallFeedbackResponse> getByCallSessionId(String callSessionId) {
        return requiredFeedbackRepository.findByCallHistoryCallSessionIdAndDeletedFalse(callSessionId)
            .map(requiredFeedback -> new CallFeedbackResponse(toRequiredPart(requiredFeedback),
                detailedFeedbackRepository.findByCallHistoryCallSessionIdAndDeletedFalse(callSessionId)
                    .map(this::toDetailedPart)
                    .orElse(null)));
    }

    // null이 아닌 조건만 합친다. 기간은 한국 시간 [from 00:00, to+1일 00:00) 시각 구간으로 바꾼다
    private Specification<RequiredFeedback> toSpecification(FeedbackSearchRequest request) {
        List<Specification<RequiredFeedback>> specifications = new ArrayList<>();
        specifications.add(FeedbackSpecifications.notDeleted());
        if (request.memberId() != null) {
            specifications.add(FeedbackSpecifications.ofMember(request.memberId()));
        }
        if (request.from() != null) {
            specifications.add(FeedbackSpecifications.createdFrom(startOfDay(request.from())));
        }
        if (request.to() != null) {
            specifications.add(FeedbackSpecifications.createdBefore(startOfDay(request.to().plusDays(1))));
        }
        if (request.rating() != null) {
            specifications.add(FeedbackSpecifications.ofRating(request.rating()));
        }
        if (request.detailedOnly()) {
            specifications.add(FeedbackSpecifications.withDetailed());
        }
        return Specification.allOf(specifications);
    }

    private Instant startOfDay(LocalDate date) {
        return date.atStartOfDay(koreaZoneId).toInstant();
    }

    // 페이지의 통화들에 대해 상세 피드백을 한 번에 조회한다(N+1 방지)
    private Set<UUID> detailedCallHistoryIds(List<RequiredFeedback> requiredFeedbacks) {
        List<UUID> callHistoryIds = requiredFeedbacks.stream()
            .map(feedback -> feedback.getCallHistory().getId())
            .toList();
        return detailedFeedbackRepository.findByCallHistoryIdInAndDeletedFalse(callHistoryIds).stream()
            .map(detailedFeedback -> detailedFeedback.getCallHistory().getId())
            .collect(Collectors.toSet());
    }

    private FeedbackListItemResponse toListItem(RequiredFeedback feedback, boolean detailedSubmitted) {
        CallHistory callHistory = feedback.getCallHistory();
        Member member = callHistory.getMember();
        return new FeedbackListItemResponse(callHistory.getCallSessionId(), member.getId(), member.getNickname(),
            member.getEmail(), callHistory.getStartedAt(), feedback.getRating(), feedback.getRevisitIntention(),
            detailedSubmitted);
    }

    private RequiredPart toRequiredPart(RequiredFeedback feedback) {
        List<AwkwardMoment> awkwardMoments = requiredFeedbackAwkwardMomentRepository
            .findByRequiredFeedbackInAndDeletedFalse(List.of(feedback)).stream()
            .map(RequiredFeedbackAwkwardMoment::getAwkwardMoment)
            .sorted(Comparator.naturalOrder())
            .toList();
        return new RequiredPart(feedback.getRating(), feedback.getRevisitIntention(),
            feedback.getPreviousCallRecall(), awkwardMoments);
    }

    private DetailedPart toDetailedPart(DetailedFeedback feedback) {
        List<StartReason> startReasons = detailedFeedbackStartReasonRepository
            .findByDetailedFeedbackInAndDeletedFalse(List.of(feedback)).stream()
            .map(DetailedFeedbackStartReason::getStartReason)
            .sorted(Comparator.naturalOrder())
            .toList();
        return new DetailedPart(
            feedback.getTimingScore(), feedback.getTimingReason(),
            feedback.getPersonaFitScore(), feedback.getPersonaFitReason(),
            feedback.getMemoryScore(), feedback.getMemoryReason(), feedback.isMemoryNotApplicable(),
            feedback.getEmpathyTrustScore(), feedback.getEmpathyTrustReason(),
            feedback.getPersonalComfortScore(), feedback.getPersonalComfortReason(),
            feedback.getStorageComfortScore(), feedback.getStorageComfortReason(),
            feedback.getFreeText(), startReasons, feedback.getStartReasonOtherText());
    }

}
