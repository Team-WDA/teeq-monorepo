package kr.co.teeq.api.onboarding.application.handler;

import java.time.Clock;
import kr.co.teeq.api.member.core.event.HandlesMemberDeletion;
import kr.co.teeq.api.member.core.event.MemberDeletedEvent;
import kr.co.teeq.api.onboarding.core.entity.OnboardingAnswer;
import kr.co.teeq.api.onboarding.core.entity.OnboardingSubmission;
import kr.co.teeq.api.onboarding.core.repository.OnboardingAnswerRepository;
import kr.co.teeq.api.onboarding.core.repository.OnboardingSubmissionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/**
 * 회원 삭제 시 온보딩 답변과 제출을 soft delete 한다.
 */
@Component
@RequiredArgsConstructor
@HandlesMemberDeletion(entities = {OnboardingAnswer.class, OnboardingSubmission.class})
public class OnboardingMemberDeletionHandler {

    private final OnboardingAnswerRepository onboardingAnswerRepository;
    private final OnboardingSubmissionRepository onboardingSubmissionRepository;
    private final Clock clock;

    @EventListener
    public void handle(MemberDeletedEvent event) {
        onboardingAnswerRepository.findByMemberIdAndDeletedFalse(event.memberId())
            .forEach(answer -> answer.delete(clock));
        onboardingSubmissionRepository.findByMemberIdAndDeletedFalse(event.memberId())
            .forEach(submission -> submission.delete(clock));
    }

}
