package kr.co.teeq.api.onboarding.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.common.core.entity.BaseEntity;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.onboarding.application.dto.request.OnboardingSubmissionSearchRequest;
import kr.co.teeq.api.onboarding.application.dto.response.OnboardingAnswerGroupResponse;
import kr.co.teeq.api.onboarding.application.dto.response.OnboardingSubmissionPageResponse;
import kr.co.teeq.api.onboarding.application.dto.response.OnboardingSubmissionResponse;
import kr.co.teeq.api.onboarding.core.constant.OnboardingOption;
import kr.co.teeq.api.onboarding.core.constant.OnboardingQuestion;
import kr.co.teeq.api.onboarding.core.entity.OnboardingAnswer;
import kr.co.teeq.api.onboarding.core.entity.OnboardingSubmission;
import kr.co.teeq.api.onboarding.core.repository.OnboardingAnswerRepository;
import kr.co.teeq.api.onboarding.core.repository.OnboardingSubmissionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class OnboardingSubmissionQueryServiceTest {

    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final Instant TIME_1 = Instant.parse("2026-10-17T00:00:00Z");
    private static final Instant TIME_2 = Instant.parse("2026-10-18T00:00:00Z");
    private static final Instant TIME_3 = Instant.parse("2026-10-19T00:00:00Z");

    @Mock
    private OnboardingSubmissionRepository onboardingSubmissionRepository;

    @Mock
    private OnboardingAnswerRepository onboardingAnswerRepository;

    private OnboardingSubmissionQueryService onboardingSubmissionQueryService;

    @BeforeEach
    void setUp() {
        onboardingSubmissionQueryService = new OnboardingSubmissionQueryService(
            onboardingSubmissionRepository, onboardingAnswerRepository, ZoneId.of("Asia/Seoul"));
    }

    private static OnboardingSubmissionSearchRequest noCondition() {
        return new OnboardingSubmissionSearchRequest(null, null, null, null, null);
    }

    private static Member member(UUID memberId) {
        Member member = mock(Member.class);
        given(member.getId()).willReturn(memberId);
        return member;
    }

    private static OnboardingSubmission submission(Member member, int number, Instant createdAt) {
        OnboardingSubmission submission = OnboardingSubmission.of(member, number, List.of("a", "b", "c"));
        ReflectionTestUtils.setField(submission, BaseEntity.class, "id", new UUID(0L, number), UUID.class);
        ReflectionTestUtils.setField(submission, BaseEntity.class, "createdAt", createdAt, Instant.class);
        return submission;
    }

    private static OnboardingAnswer answer(Member member, OnboardingSubmission submission,
        OnboardingOption option, boolean deleted) {
        OnboardingAnswer answer = OnboardingAnswer.of(member, submission, option.question(), option);
        ReflectionTestUtils.setField(answer, BaseEntity.class, "deleted", deleted, boolean.class);
        return answer;
    }

    @Test
    void search_computesSubmissionOrderFromAllSubmissionsOfTheMember() {
        Member member = member(MEMBER_ID);
        OnboardingSubmission first = submission(member, 1, TIME_1);
        OnboardingSubmission second = submission(member, 2, TIME_2);
        OnboardingSubmission third = submission(member, 3, TIME_3);
        given(onboardingSubmissionRepository.findAll(any(Specification.class), any(Pageable.class)))
            .willReturn(new PageImpl<>(List.of(third, second), PageRequest.of(0, 2), 3));
        given(onboardingSubmissionRepository.findByMemberIdInOrderByCreatedAtAscIdAsc(any()))
            .willReturn(List.of(first, second, third));
        given(onboardingAnswerRepository.findBySubmissionIdIn(any())).willReturn(List.of());

        OnboardingSubmissionPageResponse response =
            onboardingSubmissionQueryService.search(noCondition(), PageRequest.of(0, 2));

        assertThat(response.items()).extracting(OnboardingSubmissionResponse::submissionOrder).containsExactly(3, 2);
        assertThat(response.totalElements()).isEqualTo(3);
    }

    @Test
    void search_active_trueOnlyWhenSubmissionHasNonDeletedAnswer() {
        Member member = member(MEMBER_ID);
        OnboardingSubmission newer = submission(member, 2, TIME_2);
        OnboardingSubmission older = submission(member, 1, TIME_1);
        given(onboardingSubmissionRepository.findAll(any(Specification.class), any(Pageable.class)))
            .willReturn(new PageImpl<>(List.of(newer, older), PageRequest.of(0, 20), 2));
        given(onboardingSubmissionRepository.findByMemberIdInOrderByCreatedAtAscIdAsc(any()))
            .willReturn(List.of(older, newer));
        given(onboardingAnswerRepository.findBySubmissionIdIn(any())).willReturn(List.of(
            answer(member, newer, OnboardingOption.RELATIONSHIP_CLOSE_FRIEND, false),
            answer(member, older, OnboardingOption.RELATIONSHIP_CLOSE_FRIEND, true)));

        OnboardingSubmissionPageResponse response =
            onboardingSubmissionQueryService.search(noCondition(), PageRequest.of(0, 20));

        assertThat(response.items()).extracting(OnboardingSubmissionResponse::active).containsExactly(true, false);
    }

    @Test
    void search_groupsAnswersByQuestionInDeclarationOrder() {
        Member member = member(MEMBER_ID);
        OnboardingSubmission submission = submission(member, 1, TIME_1);
        given(onboardingSubmissionRepository.findAll(any(Specification.class), any(Pageable.class)))
            .willReturn(new PageImpl<>(List.of(submission), PageRequest.of(0, 20), 1));
        given(onboardingSubmissionRepository.findByMemberIdInOrderByCreatedAtAscIdAsc(any()))
            .willReturn(List.of(submission));
        given(onboardingAnswerRepository.findBySubmissionIdIn(any())).willReturn(List.of(
            answer(member, submission, OnboardingOption.AVOID_BEHAVIOR_UNASKED_ADVICE, false),
            answer(member, submission, OnboardingOption.RELATIONSHIP_LIFE_MENTOR, false),
            answer(member, submission, OnboardingOption.AVOID_BEHAVIOR_RAPID_QUESTIONS, false)));

        OnboardingSubmissionPageResponse response =
            onboardingSubmissionQueryService.search(noCondition(), PageRequest.of(0, 20));

        assertThat(response.items().get(0).answers()).containsExactly(
            new OnboardingAnswerGroupResponse(OnboardingQuestion.RELATIONSHIP,
                List.of(OnboardingOption.RELATIONSHIP_LIFE_MENTOR)),
            new OnboardingAnswerGroupResponse(OnboardingQuestion.AVOID_BEHAVIOR,
                List.of(OnboardingOption.AVOID_BEHAVIOR_RAPID_QUESTIONS,
                    OnboardingOption.AVOID_BEHAVIOR_UNASKED_ADVICE)));
    }

    @Test
    void search_fromAfterTo_throwsInvalidRequestWithoutQuerying() {
        OnboardingSubmissionSearchRequest request = new OnboardingSubmissionSearchRequest(
            null, LocalDate.of(2026, 10, 19), LocalDate.of(2026, 10, 18), null, null);

        assertThatThrownBy(() -> onboardingSubmissionQueryService.search(request, PageRequest.of(0, 20)))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.INVALID_REQUEST));
        verifyNoInteractions(onboardingSubmissionRepository, onboardingAnswerRepository);
    }

    @Test
    void search_ignoresRequestSort_usingCreatedAtDescThenIdDesc() {
        given(onboardingSubmissionRepository.findAll(any(Specification.class), any(Pageable.class)))
            .willReturn(new PageImpl<>(List.of(), PageRequest.of(1, 5), 0));

        onboardingSubmissionQueryService.search(noCondition(),
            PageRequest.of(1, 5, Sort.by("없는필드")));

        ArgumentCaptor<Pageable> captor = ArgumentCaptor.forClass(Pageable.class);
        verify(onboardingSubmissionRepository).findAll(any(Specification.class), captor.capture());
        assertThat(captor.getValue().getPageNumber()).isEqualTo(1);
        assertThat(captor.getValue().getPageSize()).isEqualTo(5);
        assertThat(captor.getValue().getSort())
            .isEqualTo(Sort.by(Sort.Order.desc("createdAt"), Sort.Order.desc("id")));
    }

    @Test
    void search_emptyPage_returnsEmptyItemsAndZeroTotal() {
        given(onboardingSubmissionRepository.findAll(any(Specification.class), any(Pageable.class)))
            .willReturn(new PageImpl<>(List.of(), PageRequest.of(0, 20), 0));

        OnboardingSubmissionPageResponse response =
            onboardingSubmissionQueryService.search(noCondition(), PageRequest.of(0, 20));

        assertThat(response.items()).isEmpty();
        assertThat(response.totalElements()).isZero();
        verifyNoInteractions(onboardingAnswerRepository);
    }

}
