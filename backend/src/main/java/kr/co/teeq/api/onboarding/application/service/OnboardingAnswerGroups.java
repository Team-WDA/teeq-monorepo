package kr.co.teeq.api.onboarding.application.service;

import java.util.Collection;
import java.util.EnumMap;
import java.util.EnumSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import kr.co.teeq.api.onboarding.application.dto.response.OnboardingAnswerGroupResponse;
import kr.co.teeq.api.onboarding.core.constant.OnboardingOption;
import kr.co.teeq.api.onboarding.core.constant.OnboardingQuestion;
import kr.co.teeq.api.onboarding.core.entity.OnboardingAnswer;

/**
 * 답변 행을 질문별 응답으로 묶는다. 질문과 선택지는 enum 선언 순서로 정렬된다.
 */
final class OnboardingAnswerGroups {

    private OnboardingAnswerGroups() {
    }

    static List<OnboardingAnswerGroupResponse> from(Collection<OnboardingAnswer> answers) {
        Map<OnboardingQuestion, Set<OnboardingOption>> optionsByQuestion = new EnumMap<>(OnboardingQuestion.class);
        answers.forEach(answer ->
            optionsByQuestion.computeIfAbsent(answer.getQuestion(), question -> EnumSet.noneOf(OnboardingOption.class))
                .add(answer.getOption()));
        // EnumMap과 EnumSet이 질문·선택지의 선언 순서를 보장한다
        return optionsByQuestion.entrySet().stream()
            .map(entry -> new OnboardingAnswerGroupResponse(entry.getKey(), List.copyOf(entry.getValue())))
            .toList();
    }

}
