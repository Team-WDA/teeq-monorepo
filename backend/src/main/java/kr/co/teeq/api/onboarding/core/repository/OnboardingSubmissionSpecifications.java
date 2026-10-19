package kr.co.teeq.api.onboarding.core.repository;

import jakarta.persistence.criteria.Root;
import jakarta.persistence.criteria.Subquery;
import java.time.Instant;
import java.util.UUID;
import kr.co.teeq.api.onboarding.core.constant.OnboardingOption;
import kr.co.teeq.api.onboarding.core.entity.OnboardingAnswer;
import kr.co.teeq.api.onboarding.core.entity.OnboardingSubmission;
import org.springframework.data.jpa.domain.Specification;

/**
 * 관리자 온보딩 제출 조회에 쓰는 검색 조건. 답변 기준 조건은 {@code exists} 서브쿼리로 만들어 제출이 중복되지 않게 한다.
 */
public final class OnboardingSubmissionSpecifications {

    private OnboardingSubmissionSpecifications() {
    }

    public static Specification<OnboardingSubmission> ofMember(UUID memberId) {
        return (root, query, builder) -> builder.equal(root.get("member").get("id"), memberId);
    }

    public static Specification<OnboardingSubmission> submittedFrom(Instant fromInclusive) {
        return (root, query, builder) -> builder.greaterThanOrEqualTo(root.<Instant>get("createdAt"), fromInclusive);
    }

    public static Specification<OnboardingSubmission> submittedBefore(Instant toExclusive) {
        return (root, query, builder) -> builder.lessThan(root.<Instant>get("createdAt"), toExclusive);
    }

    // 삭제 여부와 상관없이 그 선택지를 고른 답변이 있는 제출
    public static Specification<OnboardingSubmission> containingOption(OnboardingOption option) {
        return (root, query, builder) -> {
            Subquery<Integer> subquery = query.subquery(Integer.class);
            Root<OnboardingAnswer> answer = subquery.from(OnboardingAnswer.class);
            subquery.select(builder.literal(1)).where(
                builder.equal(answer.get("submission"), root),
                builder.equal(answer.get("option"), option));
            return builder.exists(subquery);
        };
    }

    // 삭제되지 않은 답변이 하나라도 있으면 활성 제출
    public static Specification<OnboardingSubmission> active(boolean active) {
        return (root, query, builder) -> {
            Subquery<Integer> subquery = query.subquery(Integer.class);
            Root<OnboardingAnswer> answer = subquery.from(OnboardingAnswer.class);
            subquery.select(builder.literal(1)).where(
                builder.equal(answer.get("submission"), root),
                builder.isFalse(answer.<Boolean>get("deleted")));
            return active ? builder.exists(subquery) : builder.not(builder.exists(subquery));
        };
    }

}
