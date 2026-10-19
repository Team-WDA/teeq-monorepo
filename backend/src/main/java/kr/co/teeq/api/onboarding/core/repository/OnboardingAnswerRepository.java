package kr.co.teeq.api.onboarding.core.repository;

import java.util.Collection;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.onboarding.core.entity.OnboardingAnswer;
import org.springframework.data.jpa.repository.JpaRepository;

public interface OnboardingAnswerRepository extends JpaRepository<OnboardingAnswer, UUID> {

    List<OnboardingAnswer> findByMemberIdAndDeletedFalse(UUID memberId);

    // 삭제된 행을 포함한다. 제출 이력 조회에서 제출별 답변과 활성 여부를 구할 때 쓴다
    List<OnboardingAnswer> findBySubmissionIdIn(Collection<UUID> submissionIds);

}
