package kr.co.teeq.api.onboarding.core.repository;

import java.util.Collection;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.onboarding.core.entity.OnboardingSubmission;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;

public interface OnboardingSubmissionRepository
        extends JpaRepository<OnboardingSubmission, UUID>, JpaSpecificationExecutor<OnboardingSubmission> {

    // 제출 순번 계산용. 회원별 전체 제출을 생성 시각 오름차순(같으면 id 오름차순)으로 가져온다
    List<OnboardingSubmission> findByMemberIdInOrderByCreatedAtAscIdAsc(Collection<UUID> memberIds);

    // 닉네임이 있는 활성(deleted = false) 회원 중 활성 제출(삭제되지 않은 답변이 하나 이상 있는 제출)이 있는
    // 서로 다른 회원 수(관리자 홈의 온보딩 완료율 분자). 활성 여부는 OnboardingSubmissionSpecifications.active와 같은 기준이다
    @Query("""
        select count(distinct s.member.id)
        from OnboardingSubmission s
        where s.member.deleted = false
          and s.member.nickname is not null
          and exists (
              select 1 from OnboardingAnswer a
              where a.submission = s
                and a.deleted = false)
        """)
    long countSignedUpMembersWithActiveSubmission();

}
