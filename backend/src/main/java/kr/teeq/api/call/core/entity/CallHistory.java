package kr.teeq.api.call.core.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import kr.teeq.api.common.core.entity.BaseEntity;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * AI 서버가 보고한 통화 1회의 사용 기록. 한도 합산과 통화 순번(#9)의 기준이다.
 */
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
@Table(name = "call_history")
public class CallHistory extends BaseEntity {

    @Column(nullable = false)
    private UUID memberId;

    @Column(nullable = false, length = 64)
    private String callSessionId;

    @Column(nullable = false)
    private Instant startedAt;

    @Column(nullable = false)
    private int durationSeconds;

    @Builder
    private CallHistory(UUID memberId, String callSessionId, Instant startedAt, int durationSeconds) {
        this.memberId = memberId;
        this.callSessionId = callSessionId;
        this.startedAt = startedAt;
        this.durationSeconds = durationSeconds;
    }

}
