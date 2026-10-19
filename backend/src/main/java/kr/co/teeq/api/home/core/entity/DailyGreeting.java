package kr.co.teeq.api.home.core.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.LocalDate;
import kr.co.teeq.api.common.core.entity.BaseEntity;
import kr.co.teeq.api.member.core.entity.Member;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 회원의 날짜별 오늘의 한마디. 하루(KST) 한 건만 활성 상태로 저장한다.
 */
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
@Table(name = "daily_greeting")
public class DailyGreeting extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "member_id", nullable = false)
    private Member member;

    @Column(nullable = false)
    private LocalDate greetingDate;

    @Column(nullable = false, length = 200)
    private String message;

    private DailyGreeting(Member member, LocalDate greetingDate, String message) {
        this.member = member;
        this.greetingDate = greetingDate;
        this.message = message;
    }

    public static DailyGreeting of(Member member, LocalDate greetingDate, String message) {
        return new DailyGreeting(member, greetingDate, message);
    }

}
