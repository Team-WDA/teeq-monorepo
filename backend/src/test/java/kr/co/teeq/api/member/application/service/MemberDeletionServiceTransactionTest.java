package kr.co.teeq.api.member.application.service;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.transaction.annotation.Transactional;

class MemberDeletionServiceTransactionTest {

    // 핸들러 예외 시 전체가 롤백되려면 delete가 트랜잭션 안에서 실행되어야 한다
    @Test
    void delete_isTransactional() throws NoSuchMethodException {
        assertThat(MemberDeletionService.class.getMethod("delete", UUID.class).isAnnotationPresent(Transactional.class))
            .isTrue();
    }

}
