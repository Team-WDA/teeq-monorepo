package kr.teeq.api.onboarding.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import kr.teeq.api.common.core.exception.CustomException;
import kr.teeq.api.common.core.exception.ErrorCode;
import kr.teeq.api.onboarding.application.dto.request.OnboardingAnswerGroupRequest;
import kr.teeq.api.onboarding.application.dto.response.OnboardingAnswerGroupResponse;
import kr.teeq.api.onboarding.application.dto.response.OnboardingAnswersResponse;
import kr.teeq.api.onboarding.core.constant.OnboardingOption;
import kr.teeq.api.onboarding.core.constant.OnboardingQuestion;
import kr.teeq.api.onboarding.core.entity.OnboardingAnswer;
import kr.teeq.api.onboarding.core.repository.OnboardingAnswerRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InOrder;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;

@ExtendWith(MockitoExtension.class)
class OnboardingAnswerServiceTest {

    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");

    @Mock
    private OnboardingAnswerRepository onboardingAnswerRepository;

    @InjectMocks
    private OnboardingAnswerService onboardingAnswerService;

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
        assertThatThrownBy(() -> onboardingAnswerService.replaceAnswers(MEMBER_ID, groups))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(expected));
        verifyNoInteractions(onboardingAnswerRepository);
    }

    @Test
    void replaceAnswers_valid_deletesThenSavesOneRowPerOption() {
        List<OnboardingAnswerGroupRequest> groups = validGroups();
        groups.set(6, group(OnboardingQuestion.AVOID_BEHAVIOR,
            OnboardingOption.AVOID_BEHAVIOR_RAPID_QUESTIONS, OnboardingOption.AVOID_BEHAVIOR_INTERRUPTING));

        onboardingAnswerService.replaceAnswers(MEMBER_ID, groups);

        InOrder inOrder = inOrder(onboardingAnswerRepository);
        inOrder.verify(onboardingAnswerRepository).deleteByMemberId(MEMBER_ID);
        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<OnboardingAnswer>> captor = ArgumentCaptor.forClass(List.class);
        inOrder.verify(onboardingAnswerRepository).saveAllAndFlush(captor.capture());
        assertThat(captor.getValue()).hasSize(8)
            .allSatisfy(answer -> {
                assertThat(answer.getMemberId()).isEqualTo(MEMBER_ID);
                assertThat(answer.getOption().question()).isEqualTo(answer.getQuestion());
            });
        assertThat(captor.getValue())
            .filteredOn(answer -> answer.getQuestion() == OnboardingQuestion.AVOID_BEHAVIOR)
            .extracting(OnboardingAnswer::getOption)
            .containsExactlyInAnyOrder(
                OnboardingOption.AVOID_BEHAVIOR_RAPID_QUESTIONS, OnboardingOption.AVOID_BEHAVIOR_INTERRUPTING);
    }

    @Test
    void replaceAnswers_duplicatedOptionOfOtherQuestion_duplicatedTakesPrecedence() {
        List<OnboardingAnswerGroupRequest> groups = validGroups();
        groups.set(0, group(OnboardingQuestion.RELATIONSHIP,
            OnboardingOption.PERSONALITY_CALM_WARM, OnboardingOption.PERSONALITY_CALM_WARM));
        assertFails(groups, ErrorCode.ONBOARDING_ANSWER_DUPLICATED);
    }

    @Test
    void replaceAnswers_nullOrEmptyGroups_incomplete() {
        assertFails(null, ErrorCode.ONBOARDING_ANSWER_INCOMPLETE);
        assertFails(List.of(), ErrorCode.ONBOARDING_ANSWER_INCOMPLETE);
    }

    @Test
    void replaceAnswers_nullQuestionOrOptionList_incomplete() {
        List<OnboardingAnswerGroupRequest> nullQuestion = validGroups();
        nullQuestion.set(0, new OnboardingAnswerGroupRequest(null, List.of(OnboardingOption.RELATIONSHIP_CLOSE_FRIEND)));
        assertFails(nullQuestion, ErrorCode.ONBOARDING_ANSWER_INCOMPLETE);

        List<OnboardingAnswerGroupRequest> nullOptions = validGroups();
        nullOptions.set(0, new OnboardingAnswerGroupRequest(OnboardingQuestion.RELATIONSHIP, null));
        assertFails(nullOptions, ErrorCode.ONBOARDING_ANSWER_INCOMPLETE);
    }

    @Test
    void replaceAnswers_nullOptionElement_invalidOption() {
        List<OnboardingAnswerGroupRequest> groups = validGroups();
        groups.set(0, group(OnboardingQuestion.RELATIONSHIP, (OnboardingOption) null));

        assertFails(groups, ErrorCode.INVALID_ONBOARDING_OPTION);
    }

    @Test
    void replaceAnswers_missingQuestion_incomplete() {
        List<OnboardingAnswerGroupRequest> groups = validGroups();
        groups.remove(3);

        assertFails(groups, ErrorCode.ONBOARDING_ANSWER_INCOMPLETE);
    }

    @Test
    void replaceAnswers_emptyOptions_incomplete() {
        List<OnboardingAnswerGroupRequest> groups = validGroups();
        groups.set(6, group(OnboardingQuestion.AVOID_BEHAVIOR));

        assertFails(groups, ErrorCode.ONBOARDING_ANSWER_INCOMPLETE);
    }

    @Test
    void replaceAnswers_duplicatedQuestion_duplicated() {
        List<OnboardingAnswerGroupRequest> groups = validGroups();
        groups.add(group(OnboardingQuestion.RELATIONSHIP, OnboardingOption.RELATIONSHIP_LIFE_MENTOR));

        assertFails(groups, ErrorCode.ONBOARDING_ANSWER_DUPLICATED);
    }

    @Test
    void replaceAnswers_duplicatedOption_duplicated() {
        List<OnboardingAnswerGroupRequest> groups = validGroups();
        groups.set(6, group(OnboardingQuestion.AVOID_BEHAVIOR,
            OnboardingOption.AVOID_BEHAVIOR_INTERRUPTING, OnboardingOption.AVOID_BEHAVIOR_INTERRUPTING));

        assertFails(groups, ErrorCode.ONBOARDING_ANSWER_DUPLICATED);
    }

    @Test
    void replaceAnswers_optionOfOtherQuestion_invalidOption() {
        List<OnboardingAnswerGroupRequest> groups = validGroups();
        groups.set(0, group(OnboardingQuestion.RELATIONSHIP, OnboardingOption.PERSONALITY_CALM_WARM));

        assertFails(groups, ErrorCode.INVALID_ONBOARDING_OPTION);
    }

    @Test
    void replaceAnswers_twoOptionsOnSingleQuestion_invalidOption() {
        List<OnboardingAnswerGroupRequest> groups = validGroups();
        groups.set(0, group(OnboardingQuestion.RELATIONSHIP,
            OnboardingOption.RELATIONSHIP_CLOSE_FRIEND, OnboardingOption.RELATIONSHIP_LIFE_MENTOR));

        assertFails(groups, ErrorCode.INVALID_ONBOARDING_OPTION);
    }

    @Test
    void replaceAnswers_uniqueViolation_stateConflict() {
        given(onboardingAnswerRepository.saveAllAndFlush(anyList()))
            .willThrow(new DataIntegrityViolationException("unique"));

        assertThatThrownBy(() -> onboardingAnswerService.replaceAnswers(MEMBER_ID, validGroups()))
            .isInstanceOfSatisfying(CustomException.class, exception -> {
                assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.STATE_CONFLICT);
                assertThat(exception.getCause()).isInstanceOf(DataIntegrityViolationException.class);
            });
    }

    @Test
    void getAnswers_noRows_emptyList() {
        given(onboardingAnswerRepository.findByMemberIdAndDeletedFalse(MEMBER_ID)).willReturn(List.of());

        OnboardingAnswersResponse response = onboardingAnswerService.getAnswers(MEMBER_ID);

        assertThat(response.answers()).isEmpty();
        verify(onboardingAnswerRepository, never()).deleteByMemberId(MEMBER_ID);
    }

    @Test
    void getAnswers_groupsByQuestionInEnumOrder() {
        given(onboardingAnswerRepository.findByMemberIdAndDeletedFalse(MEMBER_ID)).willReturn(List.of(
            OnboardingAnswer.of(MEMBER_ID, OnboardingQuestion.AVOID_BEHAVIOR,
                OnboardingOption.AVOID_BEHAVIOR_INTERRUPTING),
            OnboardingAnswer.of(MEMBER_ID, OnboardingQuestion.RELATIONSHIP,
                OnboardingOption.RELATIONSHIP_LIFE_MENTOR),
            OnboardingAnswer.of(MEMBER_ID, OnboardingQuestion.AVOID_BEHAVIOR,
                OnboardingOption.AVOID_BEHAVIOR_RAPID_QUESTIONS)));

        OnboardingAnswersResponse response = onboardingAnswerService.getAnswers(MEMBER_ID);

        assertThat(response.answers()).containsExactly(
            new OnboardingAnswerGroupResponse(OnboardingQuestion.RELATIONSHIP,
                List.of(OnboardingOption.RELATIONSHIP_LIFE_MENTOR)),
            new OnboardingAnswerGroupResponse(OnboardingQuestion.AVOID_BEHAVIOR,
                List.of(OnboardingOption.AVOID_BEHAVIOR_RAPID_QUESTIONS, OnboardingOption.AVOID_BEHAVIOR_INTERRUPTING)));
    }

}
