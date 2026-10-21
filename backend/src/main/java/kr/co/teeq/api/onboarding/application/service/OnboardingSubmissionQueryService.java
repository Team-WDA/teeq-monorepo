package kr.co.teeq.api.onboarding.application.service;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.onboarding.application.dto.request.OnboardingSubmissionSearchRequest;
import kr.co.teeq.api.onboarding.application.dto.response.OnboardingSubmissionPageResponse;
import kr.co.teeq.api.onboarding.application.dto.response.OnboardingSubmissionResponse;
import kr.co.teeq.api.onboarding.application.dto.response.SubmissionCharacterResponse;
import kr.co.teeq.api.onboarding.core.entity.OnboardingAnswer;
import kr.co.teeq.api.onboarding.core.entity.OnboardingSubmission;
import kr.co.teeq.api.onboarding.core.repository.OnboardingAnswerRepository;
import kr.co.teeq.api.onboarding.core.repository.OnboardingSubmissionRepository;
import kr.co.teeq.api.onboarding.core.repository.OnboardingSubmissionSpecifications;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 관리자용 온보딩 제출 이력 조회.
 */
@Service
@RequiredArgsConstructor
public class OnboardingSubmissionQueryService {

    // 요청의 정렬은 무시하고 항상 최신 제출이 먼저 오게 한다
    private static final Sort SUBMISSION_SORT = Sort.by(Sort.Order.desc("createdAt"), Sort.Order.desc("id"));

    private final OnboardingSubmissionRepository onboardingSubmissionRepository;
    private final OnboardingAnswerRepository onboardingAnswerRepository;
    private final ZoneId koreaZoneId;

    @Transactional(readOnly = true)
    public OnboardingSubmissionPageResponse search(OnboardingSubmissionSearchRequest request, Pageable pageable) {
        if (request.from() != null && request.to() != null && request.from().isAfter(request.to())) {
            throw new CustomException(ErrorCode.INVALID_REQUEST);
        }
        Pageable fixedSortPageable = PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(), SUBMISSION_SORT);
        Page<OnboardingSubmission> page =
            onboardingSubmissionRepository.findAll(toSpecification(request), fixedSortPageable);
        if (page.isEmpty()) {
            return new OnboardingSubmissionPageResponse(List.of(), page.getNumber(), page.getSize(),
                page.getTotalElements());
        }
        List<OnboardingSubmission> submissions = page.getContent();
        Map<UUID, Integer> orderBySubmissionId = submissionOrders(submissions);
        Map<UUID, List<OnboardingAnswer>> answersBySubmissionId = answersBySubmissionId(submissions);
        List<OnboardingSubmissionResponse> items = submissions.stream()
            .map(submission -> toResponse(submission, orderBySubmissionId.get(submission.getId()),
                answersBySubmissionId.getOrDefault(submission.getId(), List.of())))
            .toList();
        return new OnboardingSubmissionPageResponse(items, page.getNumber(), page.getSize(),
            page.getTotalElements());
    }

    private Specification<OnboardingSubmission> toSpecification(OnboardingSubmissionSearchRequest request) {
        List<Specification<OnboardingSubmission>> specifications = new ArrayList<>();
        if (request.memberId() != null) {
            specifications.add(OnboardingSubmissionSpecifications.ofMember(request.memberId()));
        }
        if (request.from() != null) {
            specifications.add(OnboardingSubmissionSpecifications.submittedFrom(startOfDay(request.from())));
        }
        if (request.to() != null) {
            Instant nextDayStart = startOfDay(request.to().plusDays(1));
            specifications.add(OnboardingSubmissionSpecifications.submittedBefore(nextDayStart));
        }
        if (request.optionCode() != null) {
            specifications.add(OnboardingSubmissionSpecifications.containingOption(request.optionCode()));
        }
        if (request.active() != null) {
            specifications.add(OnboardingSubmissionSpecifications.active(request.active()));
        }
        return Specification.allOf(specifications);
    }

    private Instant startOfDay(LocalDate date) {
        return date.atStartOfDay(koreaZoneId).toInstant();
    }

    // 페이지에 일부 제출만 담겨도 순번은 그 회원의 전체 제출 기준으로 센다
    private Map<UUID, Integer> submissionOrders(List<OnboardingSubmission> submissions) {
        Set<UUID> memberIds = submissions.stream()
            .map(submission -> submission.getMember().getId())
            .collect(Collectors.toSet());
        Map<UUID, Integer> countByMemberId = new HashMap<>();
        Map<UUID, Integer> orderBySubmissionId = new HashMap<>();
        for (OnboardingSubmission submission
            : onboardingSubmissionRepository.findByMemberIdInOrderByCreatedAtAscIdAsc(memberIds)) {
            int order = countByMemberId.merge(submission.getMember().getId(), 1, Integer::sum);
            orderBySubmissionId.put(submission.getId(), order);
        }
        return orderBySubmissionId;
    }

    private Map<UUID, List<OnboardingAnswer>> answersBySubmissionId(List<OnboardingSubmission> submissions) {
        Collection<UUID> submissionIds = submissions.stream().map(OnboardingSubmission::getId).toList();
        return onboardingAnswerRepository.findBySubmissionIdIn(submissionIds).stream()
            .collect(Collectors.groupingBy(answer -> answer.getSubmission().getId()));
    }

    private OnboardingSubmissionResponse toResponse(OnboardingSubmission submission, int submissionOrder,
        List<OnboardingAnswer> answers) {
        boolean active = answers.stream().anyMatch(answer -> !answer.isDeleted());
        return new OnboardingSubmissionResponse(submission.getId(), submission.getMember().getId(), submissionOrder,
            submission.getCreatedAt(), active,
            new SubmissionCharacterResponse(submission.getCharacterType(), submission.getPersonaId(),
                submission.getPersonalityTags()),
            OnboardingAnswerGroups.from(answers));
    }

}
