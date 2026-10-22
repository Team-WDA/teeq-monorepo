package kr.co.teeq.api.support.core.repository;

import static org.assertj.core.api.Assertions.assertThat;

import java.lang.reflect.Method;
import java.util.Arrays;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.Query;

/**
 * 탈퇴한 회원의 제보도 관리자 화면에 보여야 하므로, 조회 선언이 회원의 삭제 여부를 조건으로 삼지 않음을 확인한다.
 * 로컬 DB 없이 할 수 있는 선언 확인이다.
 */
class BugReportRepositoryDeclarationTest {

    @Test
    void findDetailByIdAndDeletedFalse_doesNotFilterOnMemberDeleted() throws NoSuchMethodException {
        Method method = BugReportRepository.class.getMethod("findDetailByIdAndDeletedFalse", UUID.class);

        String queryText = method.getAnnotation(Query.class).value();

        assertThat(queryText).contains("r.deleted = false");
        assertThat(queryText).doesNotContain("member.deleted");
        // 별칭으로 가져온 회원에 거는 조건도 막는다: 삭제 여부 비교는 제보 자신(r.deleted)뿐이어야 한다
        assertThat(queryText.replace("r.deleted", "")).doesNotContain(".deleted");
    }

    @Test
    void findAll_fetchesMemberWithEntityGraph() throws NoSuchMethodException {
        Method method = BugReportRepository.class.getMethod("findAll", Specification.class, Pageable.class);

        assertThat(method.getAnnotation(EntityGraph.class).attributePaths()).containsExactly("member");
    }

    @Test
    void specifications_declareNoMemberDeletedCondition() {
        // 람다가 만드는 합성 메서드는 제외하고 선언한 메서드만 본다
        assertThat(Arrays.stream(BugReportSpecifications.class.getDeclaredMethods())
            .filter(method -> !method.isSynthetic())
            .map(Method::getName))
            .containsExactlyInAnyOrder("notDeleted", "ofStatus", "ofSource");
    }

}
