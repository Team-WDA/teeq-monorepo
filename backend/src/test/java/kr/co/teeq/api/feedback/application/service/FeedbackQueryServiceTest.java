package kr.co.teeq.api.feedback.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

import jakarta.persistence.criteria.CriteriaBuilder;
import jakarta.persistence.criteria.CriteriaQuery;
import jakarta.persistence.criteria.Expression;
import jakarta.persistence.criteria.Path;
import jakarta.persistence.criteria.Root;
import jakarta.persistence.criteria.Subquery;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.call.core.constant.LimitKind;
import kr.co.teeq.api.call.core.entity.CallHistory;
import kr.co.teeq.api.common.core.entity.BaseEntity;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.feedback.application.dto.request.FeedbackSearchRequest;
import kr.co.teeq.api.feedback.application.dto.response.CallFeedbackResponse;
import kr.co.teeq.api.feedback.application.dto.response.FeedbackListItemResponse;
import kr.co.teeq.api.feedback.application.dto.response.FeedbackPageResponse;
import kr.co.teeq.api.feedback.core.constant.AwkwardMoment;
import kr.co.teeq.api.feedback.core.constant.PreviousCallRecall;
import kr.co.teeq.api.feedback.core.constant.RevisitIntention;
import kr.co.teeq.api.feedback.core.constant.StartReason;
import kr.co.teeq.api.feedback.core.entity.DetailedFeedback;
import kr.co.teeq.api.feedback.core.entity.DetailedFeedbackStartReason;
import kr.co.teeq.api.feedback.core.entity.RequiredFeedback;
import kr.co.teeq.api.feedback.core.entity.RequiredFeedbackAwkwardMoment;
import kr.co.teeq.api.feedback.core.repository.DetailedFeedbackRepository;
import kr.co.teeq.api.feedback.core.repository.DetailedFeedbackStartReasonRepository;
import kr.co.teeq.api.feedback.core.repository.RequiredFeedbackAwkwardMomentRepository;
import kr.co.teeq.api.feedback.core.repository.RequiredFeedbackRepository;
import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.member.core.entity.Member;
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
class FeedbackQueryServiceTest {

    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final UUID FIRST_CALL_ID = UUID.fromString("0199aaaa-0000-7000-8000-000000000001");
    private static final UUID SECOND_CALL_ID = UUID.fromString("0199aaaa-0000-7000-8000-000000000002");
    private static final String FIRST_SESSION_ID = "session-0001";
    private static final String SECOND_SESSION_ID = "session-0002";
    private static final Instant STARTED_AT = Instant.parse("2026-10-20T03:00:00Z");
    private static final FeedbackSearchRequest NO_CONDITION = new FeedbackSearchRequest(null, null, null, null, false);

    @Mock
    private RequiredFeedbackRepository requiredFeedbackRepository;

    @Mock
    private RequiredFeedbackAwkwardMomentRepository requiredFeedbackAwkwardMomentRepository;

    @Mock
    private DetailedFeedbackRepository detailedFeedbackRepository;

    @Mock
    private DetailedFeedbackStartReasonRepository detailedFeedbackStartReasonRepository;

    private FeedbackQueryService feedbackQueryService;

    private Member member;

    @BeforeEach
    void setUp() {
        feedbackQueryService = new FeedbackQueryService(requiredFeedbackRepository,
            requiredFeedbackAwkwardMomentRepository, detailedFeedbackRepository,
            detailedFeedbackStartReasonRepository, ZoneId.of("Asia/Seoul"));
        member = Member.createMember(LoginType.GOOGLE, "google-uid", "foo@example.com", "테스터");
        ReflectionTestUtils.setField(member, BaseEntity.class, "id", MEMBER_ID, UUID.class);
    }

    private CallHistory callHistory(UUID callHistoryId, String callSessionId) {
        CallHistory callHistory = CallHistory.pending(member, "persona-1", LimitKind.PER_DAY, STARTED_AT);
        ReflectionTestUtils.setField(callHistory, BaseEntity.class, "id", callHistoryId, UUID.class);
        callHistory.activate(callSessionId, "prompt-v1", "gpt-test");
        return callHistory;
    }

    private static RequiredFeedback required(CallHistory callHistory, int rating) {
        return RequiredFeedback.of(callHistory, rating, RevisitIntention.YES, null);
    }

    private static DetailedFeedback detailed(CallHistory callHistory, boolean memoryNotApplicable) {
        return DetailedFeedback.of(callHistory,
            4, "타이밍 좋았어",
            5, null,
            memoryNotApplicable ? null : 3, memoryNotApplicable ? null : "조금 잊었어", memoryNotApplicable,
            4, "공감됐어",
            2, null,
            1, "불안했어",
            "자유 서술", "산책하다가");
    }

    // 넘긴 Specification을 가짜 Root/CriteriaBuilder에 적용해 어떤 조건이 걸렸는지 확인한다
    @SuppressWarnings("unchecked")
    private AppliedConditions searchAndApplySpecification(FeedbackSearchRequest request) {
        given(requiredFeedbackRepository.findAll(any(Specification.class), any(Pageable.class)))
            .willReturn(new PageImpl<>(List.of(), PageRequest.of(0, 20), 0));
        feedbackQueryService.search(request, PageRequest.of(0, 20));

        ArgumentCaptor<Specification<RequiredFeedback>> captor = ArgumentCaptor.forClass(Specification.class);
        verify(requiredFeedbackRepository).findAll(captor.capture(), any(Pageable.class));

        Root<RequiredFeedback> root = mock(Root.class);
        CriteriaQuery<?> query = mock(CriteriaQuery.class);
        CriteriaBuilder builder = mock(CriteriaBuilder.class);
        Path<Boolean> deletedPath = mock(Path.class);
        Path<Integer> ratingPath = mock(Path.class);
        Path<Instant> createdAtPath = mock(Path.class);
        Path<Object> callHistoryPath = mock(Path.class);
        Path<Object> memberPath = mock(Path.class);
        Path<Object> memberIdPath = mock(Path.class);
        Subquery<Integer> subquery = mock(Subquery.class);
        Root<DetailedFeedback> detailedRoot = mock(Root.class);
        Path<Object> detailedCallHistoryPath = mock(Path.class);
        Path<Boolean> detailedDeletedPath = mock(Path.class);
        given(root.<Boolean>get("deleted")).willReturn(deletedPath);
        // 조건이 없으면 쓰이지 않으므로 느슨하게 둔다
        lenient().when(root.<Integer>get("rating")).thenReturn(ratingPath);
        lenient().when(root.<Instant>get("createdAt")).thenReturn(createdAtPath);
        lenient().when(root.get("callHistory")).thenReturn(callHistoryPath);
        lenient().when(callHistoryPath.get("member")).thenReturn(memberPath);
        lenient().when(memberPath.get("id")).thenReturn(memberIdPath);
        lenient().when(query.subquery(Integer.class)).thenReturn(subquery);
        lenient().when(subquery.from(DetailedFeedback.class)).thenReturn(detailedRoot);
        lenient().when(subquery.select(any())).thenReturn(subquery);
        lenient().when(detailedRoot.get(any(String.class))).thenReturn(mock(Path.class));
        lenient().when(detailedRoot.get("callHistory")).thenReturn(detailedCallHistoryPath);
        lenient().when(detailedRoot.<Boolean>get("deleted")).thenReturn(detailedDeletedPath);
        captor.getValue().toPredicate(root, query, builder);
        return new AppliedConditions(builder, deletedPath, ratingPath, createdAtPath, memberIdPath, subquery,
            callHistoryPath, detailedCallHistoryPath, detailedDeletedPath);
    }

    private record AppliedConditions(CriteriaBuilder builder, Path<Boolean> deletedPath, Path<Integer> ratingPath,
        Path<Instant> createdAtPath, Path<Object> memberIdPath, Subquery<Integer> subquery,
        Path<Object> callHistoryPath, Path<Object> detailedCallHistoryPath, Path<Boolean> detailedDeletedPath) {
    }

    @Test
    void search_withRating_returnsOnlyThatRating() {
        AppliedConditions applied = searchAndApplySpecification(new FeedbackSearchRequest(null, null, null, 3, false));

        verify(applied.builder()).equal(applied.ratingPath(), 3);
    }

    @Test
    void search_withoutConditions_excludesDeletedFeedbackOnly() {
        AppliedConditions applied = searchAndApplySpecification(NO_CONDITION);

        verify(applied.builder()).isFalse(applied.deletedPath());
        verify(applied.builder(), never()).equal(any(Expression.class), any(Object.class));
        verify(applied.builder(), never()).exists(any());
    }

    @Test
    void search_detailedOnly_excludesCallsWithoutDetailed() {
        AppliedConditions applied = searchAndApplySpecification(
            new FeedbackSearchRequest(null, null, null, null, true));

        verify(applied.builder()).exists(applied.subquery());
        // 서브쿼리가 같은 통화의 활성 상세 피드백만 찾는다
        verify(applied.builder()).equal(applied.detailedCallHistoryPath(), applied.callHistoryPath());
        verify(applied.builder()).isFalse(applied.detailedDeletedPath());
    }

    @Test
    void search_withMemberId_filtersByCallHistoryMember() {
        AppliedConditions applied = searchAndApplySpecification(
            new FeedbackSearchRequest(MEMBER_ID, null, null, null, false));

        verify(applied.builder()).equal(applied.memberIdPath(), MEMBER_ID);
    }

    @Test
    void search_withDateRange_convertsKoreanDatesToInstantRangeOnCreatedAt() {
        AppliedConditions applied = searchAndApplySpecification(new FeedbackSearchRequest(
            null, LocalDate.of(2026, 10, 1), LocalDate.of(2026, 10, 31), null, false));

        // 한국 시간 10/1 00:00 이상, 11/1 00:00 미만
        verify(applied.builder()).greaterThanOrEqualTo(applied.createdAtPath(), Instant.parse("2026-09-30T15:00:00Z"));
        verify(applied.builder()).lessThan(applied.createdAtPath(), Instant.parse("2026-10-31T15:00:00Z"));
    }

    @Test
    void search_fromAfterTo_throwsInvalidRequestWithoutQuerying() {
        FeedbackSearchRequest request = new FeedbackSearchRequest(
            null, LocalDate.of(2026, 10, 19), LocalDate.of(2026, 10, 18), null, false);

        assertThatThrownBy(() -> feedbackQueryService.search(request, PageRequest.of(0, 20)))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.INVALID_REQUEST));
        verifyNoInteractions(requiredFeedbackRepository, detailedFeedbackRepository);
    }

    @Test
    void search_ignoresRequestSort_usingCreatedAtDescThenIdDesc() {
        given(requiredFeedbackRepository.findAll(any(Specification.class), any(Pageable.class)))
            .willReturn(new PageImpl<>(List.of(), PageRequest.of(1, 5), 0));

        feedbackQueryService.search(NO_CONDITION, PageRequest.of(1, 5, Sort.by("없는필드")));

        ArgumentCaptor<Pageable> captor = ArgumentCaptor.forClass(Pageable.class);
        verify(requiredFeedbackRepository).findAll(any(Specification.class), captor.capture());
        assertThat(captor.getValue().getPageNumber()).isEqualTo(1);
        assertThat(captor.getValue().getPageSize()).isEqualTo(5);
        assertThat(captor.getValue().getSort())
            .isEqualTo(Sort.by(Sort.Order.desc("createdAt"), Sort.Order.desc("id")));
    }

    @Test
    @SuppressWarnings("unchecked")
    void search_mapsRowsAndMarksDetailedSubmittedWithOneLookupForThePage() {
        CallHistory first = callHistory(FIRST_CALL_ID, FIRST_SESSION_ID);
        CallHistory second = callHistory(SECOND_CALL_ID, SECOND_SESSION_ID);
        given(requiredFeedbackRepository.findAll(any(Specification.class), any(Pageable.class)))
            .willReturn(new PageImpl<>(List.of(required(first, 5), required(second, 2)), PageRequest.of(0, 20), 2));
        given(detailedFeedbackRepository.findByCallHistoryIdInAndDeletedFalse(any()))
            .willReturn(List.of(detailed(first, false)));

        FeedbackPageResponse response = feedbackQueryService.search(NO_CONDITION, PageRequest.of(0, 20));

        assertThat(response.items()).containsExactly(
            new FeedbackListItemResponse(FIRST_SESSION_ID, MEMBER_ID, "테스터", "foo@example.com", STARTED_AT, 5,
                RevisitIntention.YES, true),
            new FeedbackListItemResponse(SECOND_SESSION_ID, MEMBER_ID, "테스터", "foo@example.com", STARTED_AT, 2,
                RevisitIntention.YES, false));
        assertThat(response.totalElements()).isEqualTo(2);
        ArgumentCaptor<Collection<UUID>> callHistoryIds = ArgumentCaptor.forClass(Collection.class);
        verify(detailedFeedbackRepository).findByCallHistoryIdInAndDeletedFalse(callHistoryIds.capture());
        assertThat(callHistoryIds.getValue()).containsExactlyInAnyOrder(FIRST_CALL_ID, SECOND_CALL_ID);
    }

    @Test
    void search_emptyPage_returnsEmptyItemsWithoutDetailedLookup() {
        given(requiredFeedbackRepository.findAll(any(Specification.class), any(Pageable.class)))
            .willReturn(new PageImpl<>(List.of(), PageRequest.of(0, 20), 0));

        FeedbackPageResponse response = feedbackQueryService.search(NO_CONDITION, PageRequest.of(0, 20));

        assertThat(response.items()).isEmpty();
        assertThat(response.totalElements()).isZero();
        verifyNoInteractions(detailedFeedbackRepository);
    }

    @Test
    void getByCallSessionId_withoutAnyFeedback_returnsEmpty() {
        given(requiredFeedbackRepository.findByCallHistoryCallSessionIdAndDeletedFalse(FIRST_SESSION_ID))
            .willReturn(Optional.empty());

        assertThat(feedbackQueryService.getByCallSessionId(FIRST_SESSION_ID)).isEmpty();
        verifyNoInteractions(detailedFeedbackRepository, requiredFeedbackAwkwardMomentRepository);
    }

    @Test
    void getByCallSessionId_withRequiredOnly_hasNullDetailed() {
        RequiredFeedback requiredFeedback = RequiredFeedback.of(callHistory(FIRST_CALL_ID, FIRST_SESSION_ID), 4,
            RevisitIntention.NEUTRAL, PreviousCallRecall.UNSURE);
        given(requiredFeedbackRepository.findByCallHistoryCallSessionIdAndDeletedFalse(FIRST_SESSION_ID))
            .willReturn(Optional.of(requiredFeedback));
        // 저장 순서와 상관없이 선택지 선언 순서로 보인다
        given(requiredFeedbackAwkwardMomentRepository.findByRequiredFeedbackInAndDeletedFalse(
            List.of(requiredFeedback))).willReturn(List.of(
                RequiredFeedbackAwkwardMoment.of(requiredFeedback, AwkwardMoment.REPEAT),
                RequiredFeedbackAwkwardMoment.of(requiredFeedback, AwkwardMoment.CUT)));
        given(detailedFeedbackRepository.findByCallHistoryCallSessionIdAndDeletedFalse(FIRST_SESSION_ID))
            .willReturn(Optional.empty());

        CallFeedbackResponse response = feedbackQueryService.getByCallSessionId(FIRST_SESSION_ID).orElseThrow();

        assertThat(response.required()).isEqualTo(new CallFeedbackResponse.RequiredPart(4, RevisitIntention.NEUTRAL,
            PreviousCallRecall.UNSURE, List.of(AwkwardMoment.CUT, AwkwardMoment.REPEAT)));
        assertThat(response.detailed()).isNull();
        verifyNoInteractions(detailedFeedbackStartReasonRepository);
    }

    @Test
    void getByCallSessionId_withDetailed_mapsScoresReasonsAndStartReasons() {
        CallHistory callHistory = callHistory(FIRST_CALL_ID, FIRST_SESSION_ID);
        RequiredFeedback requiredFeedback = required(callHistory, 5);
        DetailedFeedback detailedFeedback = detailed(callHistory, true);
        given(requiredFeedbackRepository.findByCallHistoryCallSessionIdAndDeletedFalse(FIRST_SESSION_ID))
            .willReturn(Optional.of(requiredFeedback));
        given(requiredFeedbackAwkwardMomentRepository.findByRequiredFeedbackInAndDeletedFalse(
            List.of(requiredFeedback))).willReturn(List.of());
        given(detailedFeedbackRepository.findByCallHistoryCallSessionIdAndDeletedFalse(FIRST_SESSION_ID))
            .willReturn(Optional.of(detailedFeedback));
        given(detailedFeedbackStartReasonRepository.findByDetailedFeedbackInAndDeletedFalse(
            List.of(detailedFeedback))).willReturn(List.of(
                DetailedFeedbackStartReason.of(detailedFeedback, StartReason.OTHER),
                DetailedFeedbackStartReason.of(detailedFeedback, StartReason.NEED_TO_TALK)));

        CallFeedbackResponse response = feedbackQueryService.getByCallSessionId(FIRST_SESSION_ID).orElseThrow();

        assertThat(response.required().previousCallRecall()).isNull();
        assertThat(response.required().awkwardMoments()).isEmpty();
        assertThat(response.detailed()).isEqualTo(new CallFeedbackResponse.DetailedPart(
            4, "타이밍 좋았어", 5, null, null, null, true, 4, "공감됐어", 2, null, 1, "불안했어",
            "자유 서술", List.of(StartReason.NEED_TO_TALK, StartReason.OTHER), "산책하다가"));
    }

    @Test
    void getByCallSessionId_readsOnlyActiveRows() {
        RequiredFeedback requiredFeedback = required(callHistory(FIRST_CALL_ID, FIRST_SESSION_ID), 3);
        given(requiredFeedbackRepository.findByCallHistoryCallSessionIdAndDeletedFalse(FIRST_SESSION_ID))
            .willReturn(Optional.of(requiredFeedback));
        given(requiredFeedbackAwkwardMomentRepository.findByRequiredFeedbackInAndDeletedFalse(any()))
            .willReturn(List.of());
        given(detailedFeedbackRepository.findByCallHistoryCallSessionIdAndDeletedFalse(FIRST_SESSION_ID))
            .willReturn(Optional.empty());

        feedbackQueryService.getByCallSessionId(FIRST_SESSION_ID);

        // 소프트 삭제된 행은 deleted = false 조건의 조회 메서드로만 읽어 제외한다
        verify(requiredFeedbackRepository).findByCallHistoryCallSessionIdAndDeletedFalse(eq(FIRST_SESSION_ID));
        verify(requiredFeedbackAwkwardMomentRepository).findByRequiredFeedbackInAndDeletedFalse(any());
        verify(detailedFeedbackRepository).findByCallHistoryCallSessionIdAndDeletedFalse(eq(FIRST_SESSION_ID));
    }

}
