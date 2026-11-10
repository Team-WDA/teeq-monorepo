package kr.co.teeq.api.feedback.core.repository;

import jakarta.persistence.criteria.Root;
import jakarta.persistence.criteria.Subquery;
import java.time.Instant;
import java.util.UUID;
import kr.co.teeq.api.feedback.core.entity.DetailedFeedback;
import kr.co.teeq.api.feedback.core.entity.RequiredFeedback;
import org.springframework.data.jpa.domain.Specification;

/**
 * 관리자 피드백 목록(필수 피드백 기준) 조회에 쓰는 검색 조건.
 * 회원 조건은 통화 기록을 거친 경로 탐색으로 쓰고, 상세 피드백 조건은 {@code exists} 서브쿼리로 만들어 행이 중복되지 않게 한다.
 */
public final class FeedbackSpecifications {

    private FeedbackSpecifications() {
    }

    public static Specification<RequiredFeedback> notDeleted() {
        return (root, query, builder) -> builder.isFalse(root.<Boolean>get("deleted"));
    }

    public static Specification<RequiredFeedback> ofMember(UUID memberId) {
        return (root, query, builder) -> builder.equal(root.get("callHistory").get("member").get("id"), memberId);
    }

    public static Specification<RequiredFeedback> ofRating(int rating) {
        return (root, query, builder) -> builder.equal(root.<Integer>get("rating"), rating);
    }

    public static Specification<RequiredFeedback> createdFrom(Instant fromInclusive) {
        return (root, query, builder) -> builder.greaterThanOrEqualTo(root.<Instant>get("createdAt"), fromInclusive);
    }

    public static Specification<RequiredFeedback> createdBefore(Instant toExclusive) {
        return (root, query, builder) -> builder.lessThan(root.<Instant>get("createdAt"), toExclusive);
    }

    // 같은 통화에 활성(deleted = false) 상세 피드백이 있는 필수 피드백
    public static Specification<RequiredFeedback> withDetailed() {
        return (root, query, builder) -> {
            Subquery<Integer> subquery = query.subquery(Integer.class);
            Root<DetailedFeedback> detailedFeedback = subquery.from(DetailedFeedback.class);
            subquery.select(builder.literal(1)).where(
                builder.equal(detailedFeedback.get("callHistory"), root.get("callHistory")),
                builder.isFalse(detailedFeedback.<Boolean>get("deleted")));
            return builder.exists(subquery);
        };
    }

}
