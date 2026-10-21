package kr.co.teeq.api.onboarding.application.service;

import kr.co.teeq.api.common.core.constant.CharacterType;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.onboarding.application.dto.request.OnboardingAnswerGroupRequest;
import kr.co.teeq.api.onboarding.application.dto.response.OnboardingAnswerGroupResponse;
import kr.co.teeq.api.onboarding.application.dto.response.OnboardingAnswersResponse;
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
import org.mockito.InOrder;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;

@ExtendWith(MockitoExtension.class)
class OnboardingAnswerServiceTest {

    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");

    private static final Instant NOW = Instant.parse("2026-10-19T00:00:00Z");
    private static final String PERSONA_ID = "persona-1";
    private static final CharacterType CHARACTER_TYPE = CharacterType.CHARACTER_3;
    private static final List<String> PERSONALITY_TAGS = List.of("a", "b", "c");

    @Mock
    private OnboardingAnswerRepository onboardingAnswerRepository;

    @Mock
    private OnboardingSubmissionRepository onboardingSubmissionRepository;

    @Mock
    private Member member;

    private OnboardingAnswerService onboardingAnswerService;

    @BeforeEach
    void setUp() {
        onboardingAnswerService = new OnboardingAnswerService(
            onboardingAnswerRepository, onboardingSubmissionRepository, Clock.fixed(NOW, ZoneOffset.UTC));
    }

    private OnboardingAnswer previousAnswer(OnboardingQuestion question, OnboardingOption option) {
        return OnboardingAnswer.of(member, dummySubmission(), question, option);
    }

    private OnboardingSubmission dummySubmission() {
        return OnboardingSubmission.of(member, PERSONA_ID, CharacterType.CHARACTER_1, List.of("a", "b", "c"));
    }

    private static OnboardingAnswerGroupRequest group(OnboardingQuestion question, OnboardingOption... options) {
        return new OnboardingAnswerGroupRequest(question, Arrays.asList(options));
    }

    private static List<OnboardingAnswerGroupRequest> validGroups() {
        return new ArrayList<>(List.of(
            group(OnboardingQuestion.RELATIONSHIP, OnboardingOption.RELATIONSHIP_CLOSE_FRIEND),
            group(OnboardingQuestion.PERSONALITY, OnboardingOption.PERSONALITY_CALM_WARM),
            group(OnboardingQuestion.SPEECH_STYLE, OnboardingOption.SPEECH_STYLE_GENTLE_POLITE),
            group(OnboardingQuestion.VOICE_TONE, OnboardingOption.VOICE_TONE_MID_NATURAL),
            group(OnboardingQuestion.ADVICE_STYLE, OnboardingOption.ADVICE_STYLE_BALANCED),
            group(OnboardingQuestion.CONVERSATION_LEAD, OnboardingOption.CONVERSATION_LEAD_BALANCED),
            group(OnboardingQuestion.AVOID_BEHAVIOR, OnboardingOption.AVOID_BEHAVIOR_RAPID_QUESTIONS)));
    }

    private void assertFails(List<OnboardingAnswerGroupRequest> groups, ErrorCode expected) {
        assertThatThrownBy(() -> onboardingAnswerService.recordSubmission(
            member, PERSONA_ID, CHARACTER_TYPE, PERSONALITY_TAGS, groups))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(expected));
        verifyNoInteractions(onboardingAnswerRepository, onboardingSubmissionRepository);
    }

    @Test
    void recordSubmission_firstSubmission_savesSubmissionWithCharacterAndAnswers() {
        given(member.getId()).willReturn(MEMBER_ID);
        given(onboardingAnswerRepository.findByMemberIdAndDeletedFalse(MEMBER_ID)).willReturn(List.of());
        List<OnboardingAnswerGroupRequest> groups = validGroups();
        groups.set(6, group(OnboardingQuestion.AVOID_BEHAVIOR,
            OnboardingOption.AVOID_BEHAVIOR_RAPID_QUESTIONS, OnboardingOption.AVOID_BEHAVIOR_INTERRUPTING));

        onboardingAnswerService.recordSubmission(member, PERSONA_ID, CHARACTER_TYPE, PERSONALITY_TAGS, groups);

        ArgumentCaptor<OnboardingSubmission> submissionCaptor = ArgumentCaptor.forClass(OnboardingSubmission.class);
        verify(onboardingSubmissionRepository).save(submissionCaptor.capture());
        OnboardingSubmission submission = submissionCaptor.getValue();
        assertThat(submission.getMember()).isSameAs(member);
        assertThat(submission.getCharacterType()).isEqualTo(CHARACTER_TYPE);
        assertThat(submission.getPersonaId()).isEqualTo(PERSONA_ID);
        assertThat(submission.getPersonalityTags()).containsExactlyElementsOf(PERSONALITY_TAGS);
        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<OnboardingAnswer>> answerCaptor = ArgumentCaptor.forClass(List.class);
        verify(onboardingAnswerRepository).saveAllAndFlush(answerCaptor.capture());
        assertThat(answerCaptor.getValue()).hasSize(8)
            .allSatisfy(answer -> {
                assertThat(answer.getMember()).isSameAs(member);
                assertThat(answer.getSubmission()).isSameAs(submission);
                assertThat(answer.getOption().question()).isEqualTo(answer.getQuestion());
            });
        assertThat(answerCaptor.getValue())
            .filteredOn(answer -> answer.getQuestion() == OnboardingQuestion.AVOID_BEHAVIOR)
            .extracting(OnboardingAnswer::getOption)
            .containsExactlyInAnyOrder(
                OnboardingOption.AVOID_BEHAVIOR_RAPID_QUESTIONS, OnboardingOption.AVOID_BEHAVIOR_INTERRUPTING);
    }

    @Test
    void recordSubmission_resubmission_softDeletesPreviousAnswersBeforeInsert() {
        given(member.getId()).willReturn(MEMBER_ID);
        List<OnboardingAnswer> previous = List.of(
            previousAnswer(OnboardingQuestion.RELATIONSHIP, OnboardingOption.RELATIONSHIP_LIFE_MENTOR),
            previousAnswer(OnboardingQuestion.PERSONALITY, OnboardingOption.PERSONALITY_CALM_WARM));
        given(onboardingAnswerRepository.findByMemberIdAndDeletedFalse(MEMBER_ID)).willReturn(previous);

        onboardingAnswerService.recordSubmission(member, PERSONA_ID, CHARACTER_TYPE, PERSONALITY_TAGS, validGroups());

        assertThat(previous).allSatisfy(answer -> {
            assertThat(answer.isDeleted()).isTrue();
            assertThat(answer.getDeletedAt()).isEqualTo(NOW);
        });
        InOrder inOrder = inOrder(onboardingAnswerRepository);
        inOrder.verify(onboardingAnswerRepository).saveAllAndFlush(previous);
        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<OnboardingAnswer>> captor = ArgumentCaptor.forClass(List.class);
        inOrder.verify(onboardingAnswerRepository).saveAllAndFlush(captor.capture());
        assertThat(captor.getValue()).hasSize(7).noneMatch(OnboardingAnswer::isDeleted);
    }

    @Test
    void recordSubmission_sameAnswersAgain_stillCreatesNewSubmission() {
        given(member.getId()).willReturn(MEMBER_ID);
        given(onboardingAnswerRepository.findByMemberIdAndDeletedFalse(MEMBER_ID)).willReturn(List.of(
            previousAnswer(OnboardingQuestion.RELATIONSHIP, OnboardingOption.RELATIONSHIP_CLOSE_FRIEND)));

        onboardingAnswerService.recordSubmission(member, PERSONA_ID, CHARACTER_TYPE, PERSONALITY_TAGS, validGroups());

        verify(onboardingSubmissionRepository).save(any(OnboardingSubmission.class));
        verify(onboardingAnswerRepository, times(2)).saveAllAndFlush(anyList());
    }

    @Test
    void recordSubmission_incompleteGroups_throwsAndTouchesNoRepository() {
        List<OnboardingAnswerGroupRequest> groups = validGroups();
        groups.remove(6);

        assertFails(groups, ErrorCode.ONBOARDING_ANSWER_INCOMPLETE);
    }

    @Test
    void recordSubmission_duplicatedOptionOfOtherQuestion_duplicatedTakesPrecedence() {
        List<OnboardingAnswerGroupRequest> groups = validGroups();
        groups.set(0, group(OnboardingQuestion.RELATIONSHIP,
            OnboardingOption.PERSONALITY_CALM_WARM, OnboardingOption.PERSONALITY_CALM_WARM));
        assertFails(groups, ErrorCode.ONBOARDING_ANSWER_DUPLICATED);
    }

    @Test
    void recordSubmission_nullOrEmptyGroups_incomplete() {
        assertFails(null, ErrorCode.ONBOARDING_ANSWER_INCOMPLETE);
        assertFails(List.of(), ErrorCode.ONBOARDING_ANSWER_INCOMPLETE);
    }

    @Test
    void recordSubmission_nullQuestionOrOptionList_incomplete() {
        List<OnboardingAnswerGroupRequest> nullQuestion = validGroups();
        nullQuestion.set(0, new OnboardingAnswerGroupRequest(null, List.of(OnboardingOption.RELATIONSHIP_CLOSE_FRIEND)));
        assertFails(nullQuestion, ErrorCode.ONBOARDING_ANSWER_INCOMPLETE);

        List<OnboardingAnswerGroupRequest> nullOptions = validGroups();
        nullOptions.set(0, new OnboardingAnswerGroupRequest(OnboardingQuestion.RELATIONSHIP, null));
        assertFails(nullOptions, ErrorCode.ONBOARDING_ANSWER_INCOMPLETE);
    }

    @Test
    void recordSubmission_nullOptionElement_invalidOption() {
        List<OnboardingAnswerGroupRequest> groups = validGroups();
        groups.set(0, group(OnboardingQuestion.RELATIONSHIP, (OnboardingOption) null));

        assertFails(groups, ErrorCode.INVALID_ONBOARDING_OPTION);
    }

    @Test
    void recordSubmission_missingQuestion_incomplete() {
        List<OnboardingAnswerGroupRequest> groups = validGroups();
        groups.remove(3);

        assertFails(groups, ErrorCode.ONBOARDING_ANSWER_INCOMPLETE);
    }

    @Test
    void recordSubmission_emptyOptions_incomplete() {
        List<OnboardingAnswerGroupRequest> groups = validGroups();
        groups.set(6, group(OnboardingQuestion.AVOID_BEHAVIOR));

        assertFails(groups, ErrorCode.ONBOARDING_ANSWER_INCOMPLETE);
    }

    @Test
    void recordSubmission_duplicatedQuestion_duplicated() {
        List<OnboardingAnswerGroupRequest> groups = validGroups();
        groups.add(group(OnboardingQuestion.RELATIONSHIP, OnboardingOption.RELATIONSHIP_LIFE_MENTOR));

        assertFails(groups, ErrorCode.ONBOARDING_ANSWER_DUPLICATED);
    }

    @Test
    void recordSubmission_duplicatedOption_duplicated() {
        List<OnboardingAnswerGroupRequest> groups = validGroups();
        groups.set(6, group(OnboardingQuestion.AVOID_BEHAVIOR,
            OnboardingOption.AVOID_BEHAVIOR_INTERRUPTING, OnboardingOption.AVOID_BEHAVIOR_INTERRUPTING));

        assertFails(groups, ErrorCode.ONBOARDING_ANSWER_DUPLICATED);
    }

    @Test
    void recordSubmission_optionOfOtherQuestion_invalidOption() {
        List<OnboardingAnswerGroupRequest> groups = validGroups();
        groups.set(0, group(OnboardingQuestion.RELATIONSHIP, OnboardingOption.PERSONALITY_CALM_WARM));

        assertFails(groups, ErrorCode.INVALID_ONBOARDING_OPTION);
    }

    @Test
    void recordSubmission_twoOptionsOnSingleQuestion_invalidOption() {
        List<OnboardingAnswerGroupRequest> groups = validGroups();
        groups.set(0, group(OnboardingQuestion.RELATIONSHIP,
            OnboardingOption.RELATIONSHIP_CLOSE_FRIEND, OnboardingOption.RELATIONSHIP_LIFE_MENTOR));

        assertFails(groups, ErrorCode.INVALID_ONBOARDING_OPTION);
    }

    @Test
    void recordSubmission_uniqueViolation_throwsStateConflict() {
        given(member.getId()).willReturn(MEMBER_ID);
        given(onboardingAnswerRepository.findByMemberIdAndDeletedFalse(MEMBER_ID)).willReturn(List.of());
        given(onboardingAnswerRepository.saveAllAndFlush(anyList()))
            .willThrow(new DataIntegrityViolationException("unique"));

        assertThatThrownBy(() -> onboardingAnswerService.recordSubmission(
            member, PERSONA_ID, CHARACTER_TYPE, PERSONALITY_TAGS, validGroups()))
            .isInstanceOfSatisfying(CustomException.class, exception -> {
                assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.STATE_CONFLICT);
                assertThat(exception.getCause()).isInstanceOf(DataIntegrityViolationException.class);
            });
    }

    @Test
    void recordSubmission_uniqueViolationOnResubmission_throwsStateConflict() {
        given(member.getId()).willReturn(MEMBER_ID);
        List<OnboardingAnswer> previous = List.of(
            previousAnswer(OnboardingQuestion.RELATIONSHIP, OnboardingOption.RELATIONSHIP_LIFE_MENTOR));
        given(onboardingAnswerRepository.findByMemberIdAndDeletedFalse(MEMBER_ID)).willReturn(previous);
        given(onboardingAnswerRepository.saveAllAndFlush(anyList()))
            .willReturn(previous)
            .willThrow(new DataIntegrityViolationException("unique"));

        assertThatThrownBy(() -> onboardingAnswerService.recordSubmission(
            member, PERSONA_ID, CHARACTER_TYPE, PERSONALITY_TAGS, validGroups()))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
    }

    @Test
    void getAnswers_noRows_emptyList() {
        given(member.getId()).willReturn(MEMBER_ID);
        given(onboardingAnswerRepository.findByMemberIdAndDeletedFalse(MEMBER_ID)).willReturn(List.of());

        OnboardingAnswersResponse response = onboardingAnswerService.getAnswers(member);

        assertThat(response.answers()).isEmpty();
    }

    @Test
    void getAnswers_groupsByQuestionInEnumOrder() {
        given(member.getId()).willReturn(MEMBER_ID);
        given(onboardingAnswerRepository.findByMemberIdAndDeletedFalse(MEMBER_ID)).willReturn(List.of(
            OnboardingAnswer.of(member, dummySubmission(), OnboardingQuestion.AVOID_BEHAVIOR,
                OnboardingOption.AVOID_BEHAVIOR_INTERRUPTING),
            OnboardingAnswer.of(member, dummySubmission(), OnboardingQuestion.RELATIONSHIP,
                OnboardingOption.RELATIONSHIP_LIFE_MENTOR),
            OnboardingAnswer.of(member, dummySubmission(), OnboardingQuestion.AVOID_BEHAVIOR,
                OnboardingOption.AVOID_BEHAVIOR_RAPID_QUESTIONS)));

        OnboardingAnswersResponse response = onboardingAnswerService.getAnswers(member);

        assertThat(response.answers()).containsExactly(
            new OnboardingAnswerGroupResponse(OnboardingQuestion.RELATIONSHIP,
                List.of(OnboardingOption.RELATIONSHIP_LIFE_MENTOR)),
            new OnboardingAnswerGroupResponse(OnboardingQuestion.AVOID_BEHAVIOR,
                List.of(OnboardingOption.AVOID_BEHAVIOR_RAPID_QUESTIONS, OnboardingOption.AVOID_BEHAVIOR_INTERRUPTING)));
    }

    @Test
    void getSpeechStyle_말투_답변이_있으면_그_선택지를_돌려준다() {
        given(member.getId()).willReturn(MEMBER_ID);
        given(onboardingAnswerRepository.findByMemberIdAndDeletedFalse(MEMBER_ID)).willReturn(List.of(
            OnboardingAnswer.of(member, dummySubmission(), OnboardingQuestion.RELATIONSHIP,
                OnboardingOption.RELATIONSHIP_CLOSE_FRIEND),
            OnboardingAnswer.of(member, dummySubmission(), OnboardingQuestion.SPEECH_STYLE,
                OnboardingOption.SPEECH_STYLE_GENTLE_POLITE),
            OnboardingAnswer.of(member, dummySubmission(), OnboardingQuestion.VOICE_TONE,
                OnboardingOption.VOICE_TONE_MID_NATURAL)));

        OnboardingOption speechStyle = onboardingAnswerService.getSpeechStyle(member);

        assertThat(speechStyle).isEqualTo(OnboardingOption.SPEECH_STYLE_GENTLE_POLITE);
    }

    @Test
    void getSpeechStyle_말투_답변이_없으면_IllegalStateException() {
        given(member.getId()).willReturn(MEMBER_ID);
        given(onboardingAnswerRepository.findByMemberIdAndDeletedFalse(MEMBER_ID)).willReturn(List.of(
            OnboardingAnswer.of(member, dummySubmission(), OnboardingQuestion.RELATIONSHIP,
                OnboardingOption.RELATIONSHIP_CLOSE_FRIEND)));

        assertThatThrownBy(() -> onboardingAnswerService.getSpeechStyle(member))
            .isInstanceOf(IllegalStateException.class);
    }

}
