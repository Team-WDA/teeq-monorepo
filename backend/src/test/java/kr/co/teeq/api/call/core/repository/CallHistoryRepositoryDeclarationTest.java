package kr.co.teeq.api.call.core.repository;

import static org.assertj.core.api.Assertions.assertThat;

import java.lang.reflect.Method;
import java.time.Instant;
import java.util.Arrays;
import java.util.Collection;
import java.util.UUID;
import org.junit.jupiter.api.Test;
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
            .contains("as callCount", "as usedSeconds", "as lastStartedAt", "as recentCallCount");
        assertThat(queryText.split("coalesce", -1)).hasSize(3);
        assertThat(method.getReturnType()).isEqualTo(CallHistoryRepository.MemberCallSummaryRow.class);
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
