package kr.teeq.api.onboarding.application.service;

import java.util.ArrayList;
import java.util.EnumMap;
import java.util.EnumSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
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
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 온보딩 답변의 저장과 조회. 답변은 선택지당 한 행으로 저장하고, 재설정은 기존 행을 지우고 다시 넣는다.
 */
@Service
@RequiredArgsConstructor
public class OnboardingAnswerService {

    private final OnboardingAnswerRepository onboardingAnswerRepository;

    @Transactional
    public void replaceAnswers(UUID memberId, List<OnboardingAnswerGroupRequest> groups) {
        List<OnboardingAnswer> answers = validateAndToAnswers(memberId, groups);
        onboardingAnswerRepository.deleteByMemberId(memberId);
        try {
            onboardingAnswerRepository.saveAllAndFlush(answers);
        } catch (DataIntegrityViolationException exception) {
            // 같은 회원의 동시 저장이 unique 제약에 걸린 경우
            throw new CustomException(ErrorCode.STATE_CONFLICT, exception);
        }
    }

    // 저장하지 않고 검증만 한다. 다른 호출(AI 서버 등) 전에 잘못된 답변을 걸러낼 때 쓴다
    public void validateAnswers(UUID memberId, List<OnboardingAnswerGroupRequest> groups) {
        validateAndToAnswers(memberId, groups);
    }

    @Transactional(readOnly = true)
    public OnboardingAnswersResponse getAnswers(UUID memberId) {
        Map<OnboardingQuestion, Set<OnboardingOption>> optionsByQuestion = new EnumMap<>(OnboardingQuestion.class);
        onboardingAnswerRepository.findByMemberIdAndDeletedFalse(memberId).forEach(answer ->
            optionsByQuestion.computeIfAbsent(answer.getQuestion(), question -> EnumSet.noneOf(OnboardingOption.class))
                .add(answer.getOption()));
        // EnumMap과 EnumSet이 질문·선택지의 선언 순서를 보장한다
        List<OnboardingAnswerGroupResponse> groups = optionsByQuestion.entrySet().stream()
            .map(entry -> new OnboardingAnswerGroupResponse(entry.getKey(), List.copyOf(entry.getValue())))
            .toList();
        return new OnboardingAnswersResponse(groups);
    }

    // 캐릭터가 있는 회원은 온보딩을 마친 상태여야 하므로 말투 답변이 없으면 불변식 위반이다
    @Transactional(readOnly = true)
    public OnboardingOption getSpeechStyle(UUID memberId) {
        return onboardingAnswerRepository.findByMemberIdAndDeletedFalse(memberId).stream()
            .filter(answer -> answer.getQuestion() == OnboardingQuestion.SPEECH_STYLE)
            .map(OnboardingAnswer::getOption)
            .findFirst()
            .orElseThrow(() -> new IllegalStateException("온보딩 말투 답변이 없습니다"));
    }

    private List<OnboardingAnswer> validateAndToAnswers(UUID memberId, List<OnboardingAnswerGroupRequest> groups) {
        if (groups == null || groups.isEmpty()) {
            throw new CustomException(ErrorCode.ONBOARDING_ANSWER_INCOMPLETE);
        }
        Set<OnboardingQuestion> answeredQuestions = EnumSet.noneOf(OnboardingQuestion.class);
        List<OnboardingAnswer> answers = new ArrayList<>();
        for (OnboardingAnswerGroupRequest group : groups) {
            if (group == null || group.questionCode() == null || group.optionCodes() == null) {
                throw new CustomException(ErrorCode.ONBOARDING_ANSWER_INCOMPLETE);
            }
            OnboardingQuestion question = group.questionCode();
            if (!answeredQuestions.add(question)) {
                throw new CustomException(ErrorCode.ONBOARDING_ANSWER_DUPLICATED);
            }
            validateOptions(question, group.optionCodes());
            group.optionCodes().forEach(option -> answers.add(OnboardingAnswer.of(memberId, question, option)));
        }
        if (answeredQuestions.size() < OnboardingQuestion.values().length) {
            throw new CustomException(ErrorCode.ONBOARDING_ANSWER_INCOMPLETE);
        }
        return answers;
    }

    private void validateOptions(OnboardingQuestion question, List<OnboardingOption> options) {
        if (options.size() < question.minSelections()) {
            throw new CustomException(ErrorCode.ONBOARDING_ANSWER_INCOMPLETE);
        }
        Set<OnboardingOption> distinctOptions = EnumSet.noneOf(OnboardingOption.class);
        for (OnboardingOption option : options) {
            if (option == null) {
                throw new CustomException(ErrorCode.INVALID_ONBOARDING_OPTION);
            }
            if (!distinctOptions.add(option)) {
                throw new CustomException(ErrorCode.ONBOARDING_ANSWER_DUPLICATED);
            }
        }
        if (distinctOptions.stream().anyMatch(option -> option.question() != question)) {
            throw new CustomException(ErrorCode.INVALID_ONBOARDING_OPTION);
        }
        if (options.size() > question.maxSelections()) {
            throw new CustomException(ErrorCode.INVALID_ONBOARDING_OPTION);
        }
    }

}
