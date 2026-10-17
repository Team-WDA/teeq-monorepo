package kr.co.teeq.api.call.core.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import kr.co.teeq.api.call.core.constant.CallStatus;
import kr.co.teeq.api.common.core.entity.BaseEntity;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 통화 1회의 기록. 한도 합산과 통화 순번(#9)의 기준이다.
 */
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
@Table(name = "call_history")
public class CallHistory extends BaseEntity {

    @Column(nullable = false)
    private UUID memberId;

    // AI 서버가 발급하며, 세션 생성에 성공하기 전(PENDING, FAILED)에는 없다
    @Column(length = 64)
    private String callSessionId;

    @Column(nullable = false)
    private Instant startedAt;

    @Column(nullable = false)
    private int durationSeconds;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private CallStatus status;

    private Instant endedAt;

    private CallHistory(UUID memberId, Instant startedAt) {
        this.memberId = memberId;
        this.startedAt = startedAt;
        this.durationSeconds = 0;
        this.status = CallStatus.PENDING;
    }

    // AI 서버 호출 전에 선삽입하는 기록
    public static CallHistory pending(UUID memberId, Instant startedAt) {
        return new CallHistory(memberId, startedAt);
    }

    public void activate(String callSessionId) {
        transitionTo(CallStatus.IN_PROGRESS);
        this.callSessionId = callSessionId;
    }

    public void fail() {
        transitionTo(CallStatus.FAILED);
    }

    // EXPIRED 기록이 늦게 온 종료 보고로 덮어쓰이는 경우도 포함한다
    public void end(int usedSeconds, Instant endedAt) {
        transitionTo(CallStatus.ENDED);
        this.durationSeconds = usedSeconds;
        this.endedAt = endedAt;
    }

    public void expire() {
        transitionTo(CallStatus.EXPIRED);
        this.durationSeconds = 0;
    }

    private void transitionTo(CallStatus target) {
        if (!status.canTransitionTo(target)) {
            throw new CustomException(ErrorCode.STATE_CONFLICT);
        }
        this.status = target;
    }

}
