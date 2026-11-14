package kr.co.teeq.api.call.core.repository;

import static org.assertj.core.api.Assertions.assertThat;

import java.lang.reflect.Method;
import java.time.Instant;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.call.core.constant.CallStatus;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.Limit;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;

/**
 * 통화 기록 조회 선언(회원 즉시 로딩, 요약 쿼리 형태, 검색 조건 목록)을 확인한다.
 * 로컬 DB 없이 할 수 있는 선언 확인이며 JPQL·Specification의 실제 실행은 검증하지 않는다.
 */
class CallHistoryRepositoryDeclarationTest {

    @Test
    void repository_extendsSpecificationExecutor() {
        assertThat(JpaSpecificationExecutor.class).isAssignableFrom(CallHistoryRepository.class);
    }

    @Test
    void findAll_fetchesMemberWithEntityGraph() throws NoSuchMethodException {
        Method method = CallHistoryRepository.class.getMethod("findAll", Specification.class, Pageable.class);

        assertThat(method.getAnnotation(EntityGraph.class).attributePaths()).containsExactly("member");
    }

    @Test
    void summarizeByMember_declaresAggregateQuery() throws NoSuchMethodException {
        Method method = CallHistoryRepository.class.getMethod(
            "summarizeByMember", UUID.class, Collection.class, Instant.class);

        String queryText = method.getAnnotation(Query.class).value();

        assertThat(queryText).contains("c.deleted = false")
            .contains("as callCount", "as usedSeconds", "as lastStartedAt", "as recentCallCount")
            .contains("c.status not in :excludedStatuses")
            .contains("case when c.startedAt >= :recentFromInclusive then 1L else 0L end");
        assertThat(queryText.split("coalesce", -1)).hasSize(3);
        assertThat(method.getReturnType()).isEqualTo(CallHistoryRepository.MemberCallSummaryRow.class);
    }

    @Test
    void aggregateAbnormal_declaresNativeAggregateQuery() throws NoSuchMethodException {
        Method method = CallHistoryRepository.class.getMethod(
            "aggregateAbnormal", String.class, String.class, Instant.class, Instant.class, List.class, List.class);

        Query query = method.getAnnotation(Query.class);

        assertThat(query.nativeQuery()).isTrue();
        assertThat(query.value()).contains("deleted = false")
            .contains("status in (:abnormalStatuses)")
            .contains("end_reason in (:abnormalEndReasons)")
            .contains("as \"periodStart\"", "as \"abnormalCount\"")
            .contains("started_at >= :fromInclusive", "started_at < :toExclusive");
        assertThat(method.getGenericReturnType().getTypeName())
            .contains(CallHistoryRepository.AbnormalCallRow.class.getSimpleName());
    }

    @Test
    void findLatestFeedbackableCall_declaresFeedbackableRuleQuery() throws NoSuchMethodException {
        Method method = CallHistoryRepository.class.getMethod(
            "findLatestFeedbackableCall", UUID.class, CallStatus.class, CallStatus.class, Limit.class);

        String queryText = method.getAnnotation(Query.class).value();

        assertThat(queryText).contains("c.member.id = :memberId", "c.deleted = false")
            .contains("c.status = :expiredStatus")
            .contains("c.status = :endedStatus and c.durationSeconds > 0")
            .contains("order by c.startedAt desc");
        assertThat(method.getGenericReturnType().getTypeName()).contains("Optional");
    }

    @Test
    void specifications_declareExpectedConditions() {
        assertThat(Arrays.stream(CallHistorySpecifications.class.getDeclaredMethods())
            .filter(method -> !method.isSynthetic())
            .map(Method::getName))
            .containsExactlyInAnyOrder("notDeleted", "ofMember", "ofActiveMemberOnly", "memberKeywordContaining",
                "startedBetween", "ofStatus", "abnormalOnly");
    }

}
