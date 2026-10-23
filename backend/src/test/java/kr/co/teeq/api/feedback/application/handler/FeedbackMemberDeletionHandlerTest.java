package kr.co.teeq.api.feedback.application.handler;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.call.core.constant.LimitKind;
import kr.co.teeq.api.call.core.entity.CallHistory;
import kr.co.teeq.api.feedback.core.constant.AwkwardMoment;
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
import kr.co.teeq.api.member.core.event.MemberDeletedEvent;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class FeedbackMemberDeletionHandlerTest {

    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final Instant NOW = Instant.parse("2026-10-22T03:00:00Z");

    @Mock
    private RequiredFeedbackRepository requiredFeedbackRepository;

    @Mock
    private DetailedFeedbackRepository detailedFeedbackRepository;

    @Mock
    private RequiredFeedbackAwkwardMomentRepository awkwardMomentRepository;

    @Mock
    private DetailedFeedbackStartReasonRepository startReasonRepository;

    private FeedbackMemberDeletionHandler handler;

    @BeforeEach
    void setUp() {
        Clock clock = Clock.fixed(NOW, ZoneOffset.UTC);
        handler = new FeedbackMemberDeletionHandler(requiredFeedbackRepository, detailedFeedbackRepository,
            awkwardMomentRepository, startReasonRepository, clock);
    }

    private CallHistory callHistory() {
        Member member = Member.createSocialMember(LoginType.APPLE, "social-id", "a@b.c", "소연");
        return CallHistory.pending(member, "persona-id", LimitKind.PER_CALL, NOW);
    }

    private DetailedFeedback detailedFeedback(CallHistory callHistory) {
        return DetailedFeedback.of(callHistory, 5, null, 5, null, null, null, true, 5, null, 5, null, 5, null,
            null, null);
    }

    @Test
    void handle_softDeletesFeedbacksAndTheirChildren() {
        CallHistory callHistory = callHistory();
        RequiredFeedback requiredFeedback = RequiredFeedback.of(callHistory, 4, RevisitIntention.YES, null);
        RequiredFeedbackAwkwardMoment firstMoment =
            RequiredFeedbackAwkwardMoment.of(requiredFeedback, AwkwardMoment.CUT);
        RequiredFeedbackAwkwardMoment secondMoment =
            RequiredFeedbackAwkwardMoment.of(requiredFeedback, AwkwardMoment.SLOW);
        DetailedFeedback detailedFeedback = detailedFeedback(callHistory);
        DetailedFeedbackStartReason startReason =
            DetailedFeedbackStartReason.of(detailedFeedback, StartReason.NEED_TO_TALK);
        given(requiredFeedbackRepository.findByCallHistoryMemberIdAndDeletedFalse(MEMBER_ID))
            .willReturn(List.of(requiredFeedback));
        given(detailedFeedbackRepository.findByCallHistoryMemberIdAndDeletedFalse(MEMBER_ID))
            .willReturn(List.of(detailedFeedback));
        given(awkwardMomentRepository.findByRequiredFeedbackInAndDeletedFalse(List.of(requiredFeedback)))
            .willReturn(List.of(firstMoment, secondMoment));
        given(startReasonRepository.findByDetailedFeedbackInAndDeletedFalse(List.of(detailedFeedback)))
            .willReturn(List.of(startReason));

        handler.handle(new MemberDeletedEvent(MEMBER_ID));

        assertThat(requiredFeedback.isDeleted()).isTrue();
        assertThat(detailedFeedback.isDeleted()).isTrue();
        assertThat(firstMoment.isDeleted()).isTrue();
        assertThat(secondMoment.isDeleted()).isTrue();
        assertThat(startReason.isDeleted()).isTrue();
        assertThat(startReason.getDeletedAt()).isEqualTo(NOW);
    }

    @Test
    void handle_noFeedbacks_doesNotQueryChildren() {
        given(requiredFeedbackRepository.findByCallHistoryMemberIdAndDeletedFalse(MEMBER_ID))
            .willReturn(List.of());
        given(detailedFeedbackRepository.findByCallHistoryMemberIdAndDeletedFalse(MEMBER_ID))
            .willReturn(List.of());

        handler.handle(new MemberDeletedEvent(MEMBER_ID));

        verify(awkwardMomentRepository, never()).findByRequiredFeedbackInAndDeletedFalse(anyCollection());
        verify(startReasonRepository, never()).findByDetailedFeedbackInAndDeletedFalse(anyCollection());
    }

}
