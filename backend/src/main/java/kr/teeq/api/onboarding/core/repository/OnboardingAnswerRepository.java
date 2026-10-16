package kr.teeq.api.onboarding.core.repository;

import java.util.List;
import java.util.UUID;
import kr.teeq.api.onboarding.core.entity.OnboardingAnswer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface OnboardingAnswerRepository extends JpaRepository<OnboardingAnswer, UUID> {

    List<OnboardingAnswer> findByMemberIdAndDeletedFalse(UUID memberId);

    // 답변 재설정용 hard delete. 같은 트랜잭션의 이후 insert가 unique 제약과 겹치지 않도록 먼저 flush한다
    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("delete from OnboardingAnswer a where a.memberId = :memberId")
    void deleteByMemberId(@Param("memberId") UUID memberId);

}
