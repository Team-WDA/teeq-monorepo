package kr.teeq.api.feedback.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.AdditionalAnswers.returnsFirstArg;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.willAnswer;
import static org.mockito.BDDMockito.willThrow;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kr.teeq.api.call.application.dto.response.FeedbackTargetCall;
import kr.teeq.api.call.application.dto.response.LatestFeedbackableCall;
import kr.teeq.api.call.application.service.CallFeedbackTargetService;
import kr.teeq.api.common.core.exception.CustomException;
import kr.teeq.api.common.core.exception.ErrorCode;
import kr.teeq.api.feedback.application.dto.request.DetailedFeedbackRequest;
import kr.teeq.api.feedback.application.dto.request.RequiredFeedbackRequest;
import kr.teeq.api.feedback.application.dto.response.FeedbackStatusResponse;
import kr.teeq.api.feedback.application.dto.response.PendingFeedbackResponse;
import kr.teeq.api.feedback.application.dto.response.RequiredFeedbackResponse;
import kr.teeq.api.feedback.core.constant.AwkwardMoment;
import kr.teeq.api.feedback.core.constant.PreviousCallRecall;
import kr.teeq.api.feedback.core.constant.RevisitIntention;
import kr.teeq.api.feedback.core.constant.StartReason;
import kr.teeq.api.feedback.core.entity.DetailedFeedback;
import kr.teeq.api.feedback.core.entity.DetailedFeedbackStartReason;
import kr.teeq.api.feedback.core.entity.RequiredFeedback;
import kr.teeq.api.feedback.core.entity.RequiredFeedbackAwkwardMoment;
import kr.teeq.api.feedback.core.repository.DetailedFeedbackRepository;
import kr.teeq.api.feedback.core.repository.DetailedFeedbackStartReasonRepository;
import kr.teeq.api.feedback.core.repository.RequiredFeedbackAwkwardMomentRepository;
import kr.teeq.api.feedback.core.repository.RequiredFeedbackRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InOrder;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;

@ExtendWith(MockitoExtension.class)
class CallFeedbackServiceTest {

    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final UUID CALL_HISTORY_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5c");
    private static final String CALL_SESSION_ID = "session-1";

    @Mock
    private CallFeedbackTargetService callFeedbackTargetService;

    @Mock
    private RequiredFeedbackRepository requiredFeedbackRepository;

    @Mock
    private RequiredFeedbackAwkwardMomentRepository requiredFeedbackAwkwardMomentRepository;

    @Mock
    private DetailedFeedbackRepository detailedFeedbackRepository;

    @Mock
    private DetailedFeedbackStartReasonRepository detailedFeedbackStartReasonRepository;

    @InjectMocks
    private CallFeedbackService callFeedbackService;

    private void givenCallIndex(int callIndex) {
        given(callFeedbackTargetService.getFeedbackTarget(MEMBER_ID, CALL_SESSION_ID))
            .willReturn(new FeedbackTargetCall(CALL_HISTORY_ID, callIndex));
    }

    private static RequiredFeedbackRequest required(PreviousCallRecall recall, AwkwardMoment... moments) {
        return new RequiredFeedbackRequest(4, RevisitIntention.YES, recall, Arrays.asList(moments));
    }

    private static DetailedFeedbackRequest detailed(Integer memoryScore, String memoryReason,
        Boolean memoryNotApplicable, String freeText, List<StartReason> startReasons, String otherText) {
        return new DetailedFeedbackRequest(4, "  ", 5, null, memoryScore, memoryReason, memoryNotApplicable,
            3, null, 2, null, 1, null, freeText, startReasons, otherText);
    }

    private static DetailedFeedbackRequest validDetailed() {
        return detailed(3, "기억했어요", false, null, List.of(StartReason.NEED_TO_TALK), null);
    }

    private void assertErrorCode(Runnable action, ErrorCode expected) {
        assertThatThrownBy(action::run)
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(expected));
    }

    // ---- getStatus ----

    @Test
    void getStatus_firstCall_doesNotRequireRecall() {
        givenCallIndex(1);
        given(requiredFeedbackRepository.existsByCallHistoryIdAndDeletedFalse(CALL_HISTORY_ID)).willReturn(false);

        FeedbackStatusResponse response = callFeedbackService.getStatus(MEMBER_ID, CALL_SESSION_ID);

        assertThat(response).isEqualTo(new FeedbackStatusResponse(1, false, false));
    }

    @Test
    void getStatus_secondCallWithSubmittedFeedback_requiresRecallAndReportsSubmitted() {
        givenCallIndex(2);
        given(requiredFeedbackRepository.existsByCallHistoryIdAndDeletedFalse(CALL_HISTORY_ID)).willReturn(true);

        FeedbackStatusResponse response = callFeedbackService.getStatus(MEMBER_ID, CALL_SESSION_ID);

        assertThat(response).isEqualTo(new FeedbackStatusResponse(2, true, true));
    }

    // ---- findPendingFeedback ----

    @Test
    void findPendingFeedback_최근_통화가_없으면_empty() {
        given(callFeedbackTargetService.findLatestFeedbackableCall(MEMBER_ID)).willReturn(Optional.empty());

        assertThat(callFeedbackService.findPendingFeedback(MEMBER_ID)).isEmpty();
        verifyNoInteractions(requiredFeedbackRepository);
    }

    @Test
    void findPendingFeedback_필수_피드백이_이미_있으면_empty() {
        given(callFeedbackTargetService.findLatestFeedbackableCall(MEMBER_ID))
            .willReturn(Optional.of(new LatestFeedbackableCall(CALL_HISTORY_ID, "call-session-1", 3)));
        given(requiredFeedbackRepository.existsByCallHistoryIdAndDeletedFalse(CALL_HISTORY_ID)).willReturn(true);

        assertThat(callFeedbackService.findPendingFeedback(MEMBER_ID)).isEmpty();
    }

    @Test
    void findPendingFeedback_필수_피드백이_없으면_해당_통화를_돌려준다() {
        given(callFeedbackTargetService.findLatestFeedbackableCall(MEMBER_ID))
            .willReturn(Optional.of(new LatestFeedbackableCall(CALL_HISTORY_ID, "call-session-1", 3)));
        given(requiredFeedbackRepository.existsByCallHistoryIdAndDeletedFalse(CALL_HISTORY_ID)).willReturn(false);

        assertThat(callFeedbackService.findPendingFeedback(MEMBER_ID))
            .contains(new PendingFeedbackResponse("call-session-1", 3));
    }

    // ---- submitRequired: 지난 통화 기억 규칙 ----

    @Test
    void submitRequired_firstCallWithRecall_isRejected() {
        givenCallIndex(1);

        assertErrorCode(() -> callFeedbackService.submitRequired(MEMBER_ID, CALL_SESSION_ID,
            required(PreviousCallRecall.NO, AwkwardMoment.CUT)), ErrorCode.INVALID_FEEDBACK_ANSWER);
        verify(requiredFeedbackRepository, never()).saveAndFlush(any());
    }

    @Test
    void submitRequired_secondCallWithoutRecall_isRejected() {
        givenCallIndex(2);

        assertErrorCode(() -> callFeedbackService.submitRequired(MEMBER_ID, CALL_SESSION_ID,
            required(null, AwkwardMoment.CUT)), ErrorCode.INVALID_FEEDBACK_ANSWER);
        verify(requiredFeedbackRepository, never()).saveAndFlush(any());
    }

    // ---- submitRequired: 어색했던 순간 규칙 ----

    @Test
    void submitRequired_noneCombinedWithOther_isRejected() {
        givenCallIndex(1);

        assertErrorCode(() -> callFeedbackService.submitRequired(MEMBER_ID, CALL_SESSION_ID,
            required(null, AwkwardMoment.NONE, AwkwardMoment.CUT)), ErrorCode.INVALID_FEEDBACK_ANSWER);
    }

    @Test
    void submitRequired_duplicateMoments_isRejected() {
        givenCallIndex(1);

        assertErrorCode(() -> callFeedbackService.submitRequired(MEMBER_ID, CALL_SESSION_ID,
            required(null, AwkwardMoment.CUT, AwkwardMoment.CUT)), ErrorCode.INVALID_FEEDBACK_ANSWER);
    }

    @Test
    void submitRequired_noneAlone_isAccepted() {
        givenCallIndex(1);
        willAnswer(returnsFirstArg()).given(requiredFeedbackRepository).saveAndFlush(any(RequiredFeedback.class));

        callFeedbackService.submitRequired(MEMBER_ID, CALL_SESSION_ID, required(null, AwkwardMoment.NONE));

        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<RequiredFeedbackAwkwardMoment>> childCaptor = ArgumentCaptor.forClass(List.class);
        verify(requiredFeedbackAwkwardMomentRepository).saveAll(childCaptor.capture());
        assertThat(childCaptor.getValue())
            .extracting(RequiredFeedbackAwkwardMoment::getAwkwardMoment)
            .containsExactly(AwkwardMoment.NONE);
    }

    // ---- submitRequired: 저장과 응답 ----

    @Test
    void submitRequired_savesParentBeforeChildren() {
        givenCallIndex(2);
        willAnswer(returnsFirstArg()).given(requiredFeedbackRepository).saveAndFlush(any(RequiredFeedback.class));

        callFeedbackService.submitRequired(MEMBER_ID, CALL_SESSION_ID,
            required(PreviousCallRecall.UNSURE, AwkwardMoment.CUT, AwkwardMoment.SLOW));

        ArgumentCaptor<RequiredFeedback> parentCaptor = ArgumentCaptor.forClass(RequiredFeedback.class);
        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<RequiredFeedbackAwkwardMoment>> childCaptor = ArgumentCaptor.forClass(List.class);
        InOrder order = inOrder(requiredFeedbackRepository, requiredFeedbackAwkwardMomentRepository);
        order.verify(requiredFeedbackRepository).saveAndFlush(parentCaptor.capture());
        order.verify(requiredFeedbackAwkwardMomentRepository).saveAll(childCaptor.capture());
        RequiredFeedback parent = parentCaptor.getValue();
        assertThat(parent.getCallHistoryId()).isEqualTo(CALL_HISTORY_ID);
        assertThat(parent.getRating()).isEqualTo(4);
        assertThat(parent.getRevisitIntention()).isEqualTo(RevisitIntention.YES);
        assertThat(parent.getPreviousCallRecall()).isEqualTo(PreviousCallRecall.UNSURE);
        assertThat(childCaptor.getValue())
            .extracting(RequiredFeedbackAwkwardMoment::getAwkwardMoment)
            .containsExactly(AwkwardMoment.CUT, AwkwardMoment.SLOW);
        assertThat(childCaptor.getValue()).allSatisfy(child -> assertThat(child.getRequiredFeedback()).isSameAs(parent));
    }

    @Test
    void submitRequired_invitesDetailedFeedbackOnEveryThirdCall() {
        willAnswer(returnsFirstArg()).given(requiredFeedbackRepository).saveAndFlush(any(RequiredFeedback.class));

        givenCallIndex(3);
        RequiredFeedbackResponse third = callFeedbackService.submitRequired(MEMBER_ID, CALL_SESSION_ID,
            required(PreviousCallRecall.REMEMBERED, AwkwardMoment.NONE));
        givenCallIndex(4);
        RequiredFeedbackResponse fourth = callFeedbackService.submitRequired(MEMBER_ID, CALL_SESSION_ID,
            required(PreviousCallRecall.REMEMBERED, AwkwardMoment.NONE));

        assertThat(third.detailedFeedbackInvited()).isTrue();
        assertThat(fourth.detailedFeedbackInvited()).isFalse();
    }

    // ---- submitRequired: 중복 ----

    @Test
    void submitRequired_alreadySubmitted_isConflictBeforeValidation() {
        givenCallIndex(1);
        given(requiredFeedbackRepository.existsByCallHistoryIdAndDeletedFalse(CALL_HISTORY_ID)).willReturn(true);

        // 규칙을 어긴 요청이어도 이미 제출 여부가 먼저 판단된다
        assertErrorCode(() -> callFeedbackService.submitRequired(MEMBER_ID, CALL_SESSION_ID,
            required(PreviousCallRecall.NO, AwkwardMoment.CUT)), ErrorCode.FEEDBACK_ALREADY_SUBMITTED);
        verify(requiredFeedbackRepository, never()).saveAndFlush(any());
    }

    @Test
    void submitRequired_uniqueViolation_isConvertedWithCause() {
        givenCallIndex(1);
        DataIntegrityViolationException violation = new DataIntegrityViolationException("uq_required_feedback");
        willThrow(violation).given(requiredFeedbackRepository).saveAndFlush(any(RequiredFeedback.class));

        assertThatThrownBy(() -> callFeedbackService.submitRequired(MEMBER_ID, CALL_SESSION_ID,
            required(null, AwkwardMoment.CUT)))
            .isInstanceOfSatisfying(CustomException.class, exception -> {
                assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.FEEDBACK_ALREADY_SUBMITTED);
                assertThat(exception.getCause()).isSameAs(violation);
            });
        verifyNoInteractions(requiredFeedbackAwkwardMomentRepository);
    }

    // ---- submitDetailed: 검사 순서 ----

    @Test
    void submitDetailed_requiredFeedbackMissing_takesPrecedenceOverNotInvited() {
        givenCallIndex(2);
        given(requiredFeedbackRepository.existsByCallHistoryIdAndDeletedFalse(CALL_HISTORY_ID)).willReturn(false);

        assertErrorCode(() -> callFeedbackService.submitDetailed(MEMBER_ID, CALL_SESSION_ID, validDetailed()),
            ErrorCode.REQUIRED_FEEDBACK_NOT_SUBMITTED);
    }

    @Test
    void submitDetailed_notInvitedCall_isRejected() {
        givenCallIndex(2);
        given(requiredFeedbackRepository.existsByCallHistoryIdAndDeletedFalse(CALL_HISTORY_ID)).willReturn(true);

        assertErrorCode(() -> callFeedbackService.submitDetailed(MEMBER_ID, CALL_SESSION_ID, validDetailed()),
            ErrorCode.DETAILED_FEEDBACK_NOT_INVITED);
    }

    @Test
    void submitDetailed_alreadySubmitted_isConflictBeforeValidation() {
        givenInvitedCallWithRequiredFeedback();
        given(detailedFeedbackRepository.existsByCallHistoryIdAndDeletedFalse(CALL_HISTORY_ID)).willReturn(true);

        assertErrorCode(() -> callFeedbackService.submitDetailed(MEMBER_ID, CALL_SESSION_ID,
            detailed(null, null, false, null, List.of(StartReason.NEED_TO_TALK), null)),
            ErrorCode.FEEDBACK_ALREADY_SUBMITTED);
        verify(detailedFeedbackRepository, never()).saveAndFlush(any());
    }

    @Test
    void submitDetailed_uniqueViolation_isConvertedWithCause() {
        givenInvitedCallWithRequiredFeedback();
        DataIntegrityViolationException violation = new DataIntegrityViolationException("uq_detailed_feedback");
        willThrow(violation).given(detailedFeedbackRepository).saveAndFlush(any(DetailedFeedback.class));

        assertThatThrownBy(() -> callFeedbackService.submitDetailed(MEMBER_ID, CALL_SESSION_ID, validDetailed()))
            .isInstanceOfSatisfying(CustomException.class, exception -> {
                assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.FEEDBACK_ALREADY_SUBMITTED);
                assertThat(exception.getCause()).isSameAs(violation);
            });
        verifyNoInteractions(detailedFeedbackStartReasonRepository);
    }

    private void givenInvitedCallWithRequiredFeedback() {
        givenCallIndex(3);
        given(requiredFeedbackRepository.existsByCallHistoryIdAndDeletedFalse(CALL_HISTORY_ID)).willReturn(true);
    }

    // ---- submitDetailed: 기억 면제 규칙 ----

    @Test
    void submitDetailed_memoryNotApplicableWithScore_isRejected() {
        givenInvitedCallWithRequiredFeedback();

        assertErrorCode(() -> callFeedbackService.submitDetailed(MEMBER_ID, CALL_SESSION_ID,
            detailed(3, null, true, null, List.of(StartReason.NEED_TO_TALK), null)),
            ErrorCode.INVALID_FEEDBACK_ANSWER);
    }

    @Test
    void submitDetailed_memoryNotApplicableWithReason_isRejected() {
        givenInvitedCallWithRequiredFeedback();

        assertErrorCode(() -> callFeedbackService.submitDetailed(MEMBER_ID, CALL_SESSION_ID,
            detailed(null, "이유", true, null, List.of(StartReason.NEED_TO_TALK), null)),
            ErrorCode.INVALID_FEEDBACK_ANSWER);
    }

    @Test
    void submitDetailed_memoryApplicableWithoutScore_isRejected() {
        givenInvitedCallWithRequiredFeedback();

        assertErrorCode(() -> callFeedbackService.submitDetailed(MEMBER_ID, CALL_SESSION_ID,
            detailed(null, null, false, null, List.of(StartReason.NEED_TO_TALK), null)),
            ErrorCode.INVALID_FEEDBACK_ANSWER);
    }

    @Test
    void submitDetailed_blankMemoryReasonWithNotApplicable_isTreatedAsAbsent() {
        givenInvitedCallWithRequiredFeedback();
        willAnswer(returnsFirstArg()).given(detailedFeedbackRepository).saveAndFlush(any(DetailedFeedback.class));

        callFeedbackService.submitDetailed(MEMBER_ID, CALL_SESSION_ID,
            detailed(null, "   ", true, null, List.of(StartReason.NEED_TO_TALK), null));

        ArgumentCaptor<DetailedFeedback> parentCaptor = ArgumentCaptor.forClass(DetailedFeedback.class);
        verify(detailedFeedbackRepository).saveAndFlush(parentCaptor.capture());
        assertThat(parentCaptor.getValue().getMemoryReason()).isNull();
        assertThat(parentCaptor.getValue().getMemoryScore()).isNull();
    }

    // ---- submitDetailed: 시작 이유 규칙 ----

    @Test
    void submitDetailed_duplicateStartReasons_isRejected() {
        givenInvitedCallWithRequiredFeedback();

        assertErrorCode(() -> callFeedbackService.submitDetailed(MEMBER_ID, CALL_SESSION_ID,
            detailed(3, null, false, null, List.of(StartReason.NEED_TO_TALK, StartReason.NEED_TO_TALK), null)),
            ErrorCode.INVALID_FEEDBACK_ANSWER);
    }

    @Test
    void submitDetailed_otherTextWithoutOtherReason_isRejected() {
        givenInvitedCallWithRequiredFeedback();

        assertErrorCode(() -> callFeedbackService.submitDetailed(MEMBER_ID, CALL_SESSION_ID,
            detailed(3, null, false, null, List.of(StartReason.NEED_TO_TALK), "그냥")),
            ErrorCode.INVALID_FEEDBACK_ANSWER);
    }

    @Test
    void submitDetailed_blankOtherTextWithoutOtherReason_isAcceptedAsAbsent() {
        givenInvitedCallWithRequiredFeedback();
        willAnswer(returnsFirstArg()).given(detailedFeedbackRepository).saveAndFlush(any(DetailedFeedback.class));

        callFeedbackService.submitDetailed(MEMBER_ID, CALL_SESSION_ID,
            detailed(3, null, false, null, List.of(StartReason.NEED_TO_TALK), "   "));

        verify(detailedFeedbackRepository).saveAndFlush(any(DetailedFeedback.class));
    }

    // ---- submitDetailed: 저장 ----

    @Test
    void submitDetailed_savesNormalizedValuesParentBeforeChildren() {
        givenInvitedCallWithRequiredFeedback();
        willAnswer(returnsFirstArg()).given(detailedFeedbackRepository).saveAndFlush(any(DetailedFeedback.class));

        // 위치 인자 순서가 바뀌면 단언이 깨지도록 필드마다 서로 다른 값을 쓴다
        callFeedbackService.submitDetailed(MEMBER_ID, CALL_SESSION_ID, new DetailedFeedbackRequest(
            1, " 타이밍 이유 ", 2, " 페르소나 이유 ", 3, " 기억했어요 ", false,
            4, " 공감 이유 ", 5, " 편안함 이유 ", 1, " 저장 이유 ", " 자유 의견 ",
            List.of(StartReason.OTHER, StartReason.NEED_TO_TALK), " 심심해서 "));

        ArgumentCaptor<DetailedFeedback> parentCaptor = ArgumentCaptor.forClass(DetailedFeedback.class);
        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<DetailedFeedbackStartReason>> childCaptor = ArgumentCaptor.forClass(List.class);
        InOrder order = inOrder(detailedFeedbackRepository, detailedFeedbackStartReasonRepository);
        order.verify(detailedFeedbackRepository).saveAndFlush(parentCaptor.capture());
        order.verify(detailedFeedbackStartReasonRepository).saveAll(childCaptor.capture());
        DetailedFeedback parent = parentCaptor.getValue();
        assertThat(parent.getCallHistoryId()).isEqualTo(CALL_HISTORY_ID);
        assertThat(parent.getTimingScore()).isEqualTo(1);
        assertThat(parent.getTimingReason()).isEqualTo("타이밍 이유");
        assertThat(parent.getPersonaFitScore()).isEqualTo(2);
        assertThat(parent.getPersonaFitReason()).isEqualTo("페르소나 이유");
        assertThat(parent.getMemoryScore()).isEqualTo(3);
        assertThat(parent.getMemoryReason()).isEqualTo("기억했어요");
        assertThat(parent.isMemoryNotApplicable()).isFalse();
        assertThat(parent.getEmpathyTrustScore()).isEqualTo(4);
        assertThat(parent.getEmpathyTrustReason()).isEqualTo("공감 이유");
        assertThat(parent.getPersonalComfortScore()).isEqualTo(5);
        assertThat(parent.getPersonalComfortReason()).isEqualTo("편안함 이유");
        assertThat(parent.getStorageComfortScore()).isEqualTo(1);
        assertThat(parent.getStorageComfortReason()).isEqualTo("저장 이유");
        assertThat(parent.getFreeText()).isEqualTo("자유 의견");
        assertThat(parent.getStartReasonOtherText()).isEqualTo("심심해서");
        assertThat(childCaptor.getValue())
            .extracting(DetailedFeedbackStartReason::getStartReason)
            .containsExactly(StartReason.OTHER, StartReason.NEED_TO_TALK);
    }

}
