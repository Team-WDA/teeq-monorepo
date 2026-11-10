package kr.co.teeq.api.call.core.repository;

import java.time.Instant;
import java.util.UUID;
import kr.co.teeq.api.call.core.constant.AbnormalCallCriteria;
import kr.co.teeq.api.call.core.constant.CallStatus;
import kr.co.teeq.api.call.core.entity.CallHistory;
import kr.co.teeq.api.member.core.repository.MemberSpecifications;
import org.springframework.data.jpa.domain.Specification;

/**
 * 관리자 통화 목록 조회에 쓰는 검색 조건.
 * 회원 조건은 조인을 따로 만들지 않고 경로 탐색으로 써서 조인이 한 번으로 합쳐지게 한다.
 */
public final class CallHistorySpecifications {

    private static final char LIKE_ESCAPE_CHARACTER = '\\';

    private CallHistorySpecifications() {
    }

    public static Specification<CallHistory> notDeleted() {
        return (root, query, builder) -> builder.isFalse(root.<Boolean>get("deleted"));
    }

    public static Specification<CallHistory> ofMember(UUID memberId) {
        return (root, query, builder) -> builder.equal(root.get("member").get("id"), memberId);
    }

    // 삭제된 회원의 통화는 제외한다
    public static Specification<CallHistory> ofActiveMemberOnly() {
        return (root, query, builder) -> builder.isFalse(root.get("member").<Boolean>get("deleted"));
    }

    // 회원 이메일 또는 닉네임에 키워드가 포함된 통화(대소문자 무시)
    public static Specification<CallHistory> memberKeywordContaining(String keyword) {
        return (root, query, builder) -> {
            String pattern = MemberSpecifications.toLikePattern(keyword);
            return builder.or(
                builder.like(builder.lower(root.get("member").<String>get("email")), pattern,
                    LIKE_ESCAPE_CHARACTER),
                builder.like(builder.lower(root.get("member").<String>get("nickname")), pattern,
                    LIKE_ESCAPE_CHARACTER));
        };
    }

    // 시작 시각이 [fromInclusive, toExclusive)인 통화. 한쪽이 null이면 그쪽은 제한하지 않는다
    public static Specification<CallHistory> startedBetween(Instant fromInclusive, Instant toExclusive) {
        return (root, query, builder) -> {
            var predicate = builder.conjunction();
            if (fromInclusive != null) {
                predicate = builder.and(predicate, builder.greaterThanOrEqualTo(root.<Instant>get("startedAt"),
                    fromInclusive));
            }
            if (toExclusive != null) {
                predicate = builder.and(predicate, builder.lessThan(root.<Instant>get("startedAt"), toExclusive));
            }
            return predicate;
        };
    }

    public static Specification<CallHistory> ofStatus(CallStatus status) {
        return (root, query, builder) -> builder.equal(root.get("status"), status);
    }

    // 비정상 통화: 시작 실패·만료이거나, 종료됐지만 사유가 에이전트 오류·배정 실패인 통화
    public static Specification<CallHistory> abnormalOnly() {
        return (root, query, builder) -> builder.or(
            root.get("status").in(AbnormalCallCriteria.STATUSES),
            builder.and(
                builder.equal(root.get("status"), CallStatus.ENDED),
                root.get("endReason").in(AbnormalCallCriteria.ENDED_END_REASONS)));
    }

}
