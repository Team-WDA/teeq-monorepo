package kr.co.teeq.api.home.core.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import java.time.LocalDate;
import java.util.UUID;
import kr.co.teeq.api.common.core.entity.BaseEntity;
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

    @Column(nullable = false)
    private UUID memberId;

    @Column(nullable = false)
    private LocalDate greetingDate;

    @Column(nullable = false, length = 200)
    private String message;

    private DailyGreeting(UUID memberId, LocalDate greetingDate, String message) {
        this.memberId = memberId;
        this.greetingDate = greetingDate;
        this.message = message;
    }

    public static DailyGreeting of(UUID memberId, LocalDate greetingDate, String message) {
        return new DailyGreeting(memberId, greetingDate, message);
    }

}
