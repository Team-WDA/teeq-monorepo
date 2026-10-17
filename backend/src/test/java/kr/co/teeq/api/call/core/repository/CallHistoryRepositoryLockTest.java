package kr.co.teeq.api.call.core.repository;

import static org.assertj.core.api.Assertions.assertThat;

import jakarta.persistence.LockModeType;
import java.lang.reflect.Method;
import java.time.Instant;
import java.util.Collection;
import java.util.UUID;
import kr.co.teeq.api.call.core.constant.CallStatus;
import org.junit.jupiter.api.Test;
import org.springframework.data.jpa.repository.Lock;

class CallHistoryRepositoryLockTest {

    // Mockito로는 실제 잠금 동작을 검증할 수 없으므로 잠금 선언 여부만 고정한다
    @Test
    void 만료_후보_조회는_비관적_쓰기_잠금을_선언한다() throws NoSuchMethodException {
        Method method = CallHistoryRepository.class.getMethod(
            "findByMemberIdAndStatusInAndStartedAtLessThanEqualAndDeletedFalse",
            UUID.class, Collection.class, Instant.class);

        Lock lock = method.getAnnotation(Lock.class);

        assertThat(lock).isNotNull();
        assertThat(lock.value()).isEqualTo(LockModeType.PESSIMISTIC_WRITE);
    }

}
