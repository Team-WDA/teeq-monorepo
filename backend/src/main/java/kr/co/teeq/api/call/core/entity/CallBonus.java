package kr.co.teeq.api.call.core.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Clock;
import java.time.LocalDate;
import kr.co.teeq.api.common.core.entity.BaseEntity;
import kr.co.teeq.api.member.core.entity.Member;
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

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "member_id", nullable = false)
    private Member member;

    @Column(nullable = false)
    private LocalDate bonusDate;

    @Column(nullable = false)
    private int seconds;

    @Column(nullable = false, length = 200)
    private String reason;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "granted_by_member_id", nullable = false)
    private Member grantedBy;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "canceled_by_member_id")
    private Member canceledBy;

    private CallBonus(Member member, LocalDate bonusDate, int seconds, String reason, Member grantedBy) {
        this.member = member;
        this.bonusDate = bonusDate;
        this.seconds = seconds;
        this.reason = reason;
        this.grantedBy = grantedBy;
    }

    public static CallBonus grant(Member member, LocalDate bonusDate, int seconds, String reason,
        Member grantedBy) {
        return new CallBonus(member, bonusDate, seconds, reason, grantedBy);
    }

    // 취소한 관리자를 남기고 soft delete 한다
    public void cancel(Member canceledBy, Clock clock) {
        this.canceledBy = canceledBy;
        delete(clock);
    }

}
