package kr.co.teeq.api.onboarding.core.repository;

import java.util.Collection;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.onboarding.core.entity.OnboardingSubmission;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

public interface OnboardingSubmissionRepository
        extends JpaRepository<OnboardingSubmission, UUID>, JpaSpecificationExecutor<OnboardingSubmission> {

    // 제출 순번 계산용. 회원별 전체 제출을 생성 시각 오름차순(같으면 id 오름차순)으로 가져온다
    List<OnboardingSubmission> findByMemberIdInOrderByCreatedAtAscIdAsc(Collection<UUID> memberIds);

}
