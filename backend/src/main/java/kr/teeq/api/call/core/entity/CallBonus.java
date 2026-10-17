package kr.teeq.api.call.core.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import java.time.Clock;
import java.time.LocalDate;
import java.util.UUID;
import kr.teeq.api.common.core.entity.BaseEntity;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 관리자가 특정 회원에게 부여한 하루 추가 통화 시간. bonusDate(KST)에만 유효하며 취소하면 soft delete 된다.
 */
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
@Table(name = "call_bonus")
public class CallBonus extends BaseEntity {

    @Column(nullable = false)
    private UUID memberId;

    @Column(nullable = false)
    private LocalDate bonusDate;

    @Column(nullable = false)
    private int seconds;

    @Column(nullable = false, length = 200)
    private String reason;

    @Column(nullable = false)
    private UUID grantedByMemberId;

    private UUID canceledByMemberId;

    private CallBonus(UUID memberId, LocalDate bonusDate, int seconds, String reason, UUID grantedByMemberId) {
        this.memberId = memberId;
        this.bonusDate = bonusDate;
        this.seconds = seconds;
        this.reason = reason;
        this.grantedByMemberId = grantedByMemberId;
    }

    public static CallBonus grant(UUID memberId, LocalDate bonusDate, int seconds, String reason,
        UUID grantedByMemberId) {
        return new CallBonus(memberId, bonusDate, seconds, reason, grantedByMemberId);
    }

    // 취소한 관리자를 남기고 soft delete 한다
    public void cancel(UUID canceledByMemberId, Clock clock) {
        this.canceledByMemberId = canceledByMemberId;
        delete(clock);
    }

}
