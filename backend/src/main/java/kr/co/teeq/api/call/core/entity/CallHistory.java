package kr.co.teeq.api.call.core.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;
import kr.co.teeq.api.call.core.constant.CallStatus;
import kr.co.teeq.api.call.core.constant.EndReason;
import kr.co.teeq.api.call.core.constant.LimitKind;
import kr.co.teeq.api.common.core.entity.BaseEntity;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.entity.Member;
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

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "member_id", nullable = false)
    private Member member;

    // AI 서버가 발급하며, 세션 생성에 성공하기 전(PENDING, FAILED)에는 없다
    @Column(length = 64)
    private String callSessionId;

    // 통화 시작 시점의 persona. 이후 온보딩을 다시 해도 이 기록은 바뀌지 않는다
    @Column(nullable = false, length = 64)
    private String personaId;

    // maxDurationSeconds를 정한 한도 종류
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private LimitKind limitKind;

    // AI 서버가 알려 주는 실행 정보. 응답에 없으면 null
    @Column(length = 100)
    private String promptVersion;

    @Column(length = 100)
    private String llmModel;

    @Column(nullable = false)
    private Instant startedAt;

    @Column(nullable = false)
    private int durationSeconds;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private CallStatus status;

    private Instant endedAt;

    // 종료 보고 전에는 null
    @Enumerated(EnumType.STRING)
    @Column(length = 30)
    private EndReason endReason;

    private CallHistory(Member member, String personaId, LimitKind limitKind, Instant startedAt) {
        this.member = member;
        this.personaId = personaId;
        this.limitKind = limitKind;
        this.startedAt = startedAt;
        this.durationSeconds = 0;
        this.status = CallStatus.PENDING;
    }

    // AI 서버 호출 전에 선삽입하는 기록
    public static CallHistory pending(Member member, String personaId, LimitKind limitKind, Instant startedAt) {
        return new CallHistory(member, personaId, limitKind, startedAt);
    }

    public void activate(String callSessionId, String promptVersion, String llmModel) {
        transitionTo(CallStatus.IN_PROGRESS);
        this.callSessionId = callSessionId;
        this.promptVersion = promptVersion;
        this.llmModel = llmModel;
    }

    public void fail() {
        transitionTo(CallStatus.FAILED);
    }

    // EXPIRED 기록이 늦게 온 종료 보고로 덮어쓰이는 경우도 포함한다
    public void end(int usedSeconds, Instant endedAt, EndReason endReason) {
        transitionTo(CallStatus.ENDED);
        this.durationSeconds = usedSeconds;
        this.endedAt = endedAt;
        this.endReason = endReason;
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
