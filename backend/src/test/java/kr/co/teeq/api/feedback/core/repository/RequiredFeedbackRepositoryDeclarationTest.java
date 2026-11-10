package kr.co.teeq.api.feedback.core.repository;

import static org.assertj.core.api.Assertions.assertThat;

import java.lang.reflect.Method;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.EntityGraph;

/**
 * 피드백 목록이 행마다 통화·회원을 따로 조회하지 않도록(N+1) 목록 조회 선언이 둘을 함께 가져오는지 확인한다.
 * 로컬 DB 없이 할 수 있는 선언 확인이다.
 */
class RequiredFeedbackRepositoryDeclarationTest {

    @Test
    void findAll_fetchesCallHistoryAndMemberWithEntityGraph() throws NoSuchMethodException {
        Method method = RequiredFeedbackRepository.class.getMethod("findAll", Specification.class, Pageable.class);

        assertThat(method.getAnnotation(EntityGraph.class).attributePaths())
            .containsExactlyInAnyOrder("callHistory", "callHistory.member");
    }

}
