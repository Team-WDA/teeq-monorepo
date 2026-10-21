package kr.co.teeq.api.onboarding.application.service;

import java.time.Clock;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;
import kr.co.teeq.api.common.core.constant.CharacterType;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.onboarding.application.dto.request.OnboardingAnswerGroupRequest;
import kr.co.teeq.api.onboarding.application.dto.response.OnboardingAnswersResponse;
import kr.co.teeq.api.onboarding.core.constant.OnboardingOption;
import kr.co.teeq.api.onboarding.core.constant.OnboardingQuestion;
import kr.co.teeq.api.onboarding.core.entity.OnboardingAnswer;
import kr.co.teeq.api.onboarding.core.entity.OnboardingSubmission;
import kr.co.teeq.api.onboarding.core.repository.OnboardingAnswerRepository;
import kr.co.teeq.api.onboarding.core.repository.OnboardingSubmissionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 온보딩 답변의 저장과 조회. 답변은 선택지당 한 행으로 저장하고, 재제출은 기존 행을 soft delete하고 새 제출과 행을 넣는다.
 */
@Service
@RequiredArgsConstructor
public class OnboardingAnswerService {

    private final OnboardingAnswerRepository onboardingAnswerRepository;
    private final OnboardingSubmissionRepository onboardingSubmissionRepository;
    private final Clock clock;

    /**
     * 온보딩 제출 1회를 기록한다. 이전 활성 답변은 soft delete로 남기고, 새 제출과 새 답변 행을 만든다.
     */
    @Transactional
    public void recordSubmission(Member member, String personaId, CharacterType characterType,
        List<String> personalityTags, List<OnboardingAnswerGroupRequest> groups) {
        List<ValidatedAnswer> validatedAnswers = validate(groups);
        List<OnboardingAnswer> previousAnswers =
            onboardingAnswerRepository.findByMemberIdAndDeletedFalse(member.getId());
        if (!previousAnswers.isEmpty()) {
            previousAnswers.forEach(answer -> answer.delete(clock));
            // 새 답변 insert가 partial unique index와 겹치지 않도록 soft delete를 먼저 DB에 반영한다
            onboardingAnswerRepository.saveAllAndFlush(previousAnswers);
        }
        OnboardingSubmission submission = OnboardingSubmission.of(member, personaId, characterType, personalityTags);
        try {
            onboardingSubmissionRepository.save(submission);
            onboardingAnswerRepository.saveAllAndFlush(validatedAnswers.stream()
                .map(validated -> OnboardingAnswer.of(member, submission, validated.question(), validated.option()))
                .toList());
        } catch (DataIntegrityViolationException exception) {
            // 같은 회원의 동시 저장이 unique 제약에 걸린 경우
            throw new CustomException(ErrorCode.STATE_CONFLICT, exception);
        }
    }

    // 저장하지 않고 검증만 한다. 다른 호출(AI 서버 등) 전에 잘못된 답변을 걸러낼 때 쓴다
    public void validateAnswers(List<OnboardingAnswerGroupRequest> groups) {
        validate(groups);
    }

    @Transactional(readOnly = true)
    public OnboardingAnswersResponse getAnswers(Member member) {
        return new OnboardingAnswersResponse(OnboardingAnswerGroups.from(
            onboardingAnswerRepository.findByMemberIdAndDeletedFalse(member.getId())));
    }

    // 캐릭터가 있는 회원은 온보딩을 마친 상태여야 하므로 말투 답변이 없으면 불변식 위반이다
    @Transactional(readOnly = true)
    public OnboardingOption getSpeechStyle(Member member) {
        return onboardingAnswerRepository.findByMemberIdAndDeletedFalse(member.getId()).stream()
            .filter(answer -> answer.getQuestion() == OnboardingQuestion.SPEECH_STYLE)
            .map(OnboardingAnswer::getOption)
            .findFirst()
            .orElseThrow(() -> new IllegalStateException("온보딩 말투 답변이 없습니다"));
    }

    // 엔티티는 만들지 않고 검증된 (질문, 선택지) 쌍만 돌려준다
    private List<ValidatedAnswer> validate(List<OnboardingAnswerGroupRequest> groups) {
        if (groups == null || groups.isEmpty()) {
            throw new CustomException(ErrorCode.ONBOARDING_ANSWER_INCOMPLETE);
        }
        Set<OnboardingQuestion> answeredQuestions = EnumSet.noneOf(OnboardingQuestion.class);
        List<ValidatedAnswer> validatedAnswers = new ArrayList<>();
        for (OnboardingAnswerGroupRequest group : groups) {
            if (group == null || group.questionCode() == null || group.optionCodes() == null) {
                throw new CustomException(ErrorCode.ONBOARDING_ANSWER_INCOMPLETE);
            }
            OnboardingQuestion question = group.questionCode();
            if (!answeredQuestions.add(question)) {
                throw new CustomException(ErrorCode.ONBOARDING_ANSWER_DUPLICATED);
            }
            validateOptions(question, group.optionCodes());
            group.optionCodes().forEach(option -> validatedAnswers.add(new ValidatedAnswer(question, option)));
        }
        if (answeredQuestions.size() < OnboardingQuestion.values().length) {
            throw new CustomException(ErrorCode.ONBOARDING_ANSWER_INCOMPLETE);
        }
        return validatedAnswers;
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

    private record ValidatedAnswer(OnboardingQuestion question, OnboardingOption option) {

    }

}
