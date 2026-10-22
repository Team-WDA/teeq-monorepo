package kr.co.teeq.api.call.core.constant;

import java.util.Set;

/**
 * 통화 기록의 상태. 허용되는 전이는 {@link #canTransitionTo(CallStatus)}가 정한다.
 */
public enum CallStatus {
    PENDING,
    IN_PROGRESS,
    ENDED,
    FAILED,
    EXPIRED;

    // 진행 중으로 보는 상태. 회원당 하나만 허용하며 통화 시작과 회원 삭제가 같은 기준을 쓴다
    public static final Set<CallStatus> ACTIVE_STATUSES = Set.of(PENDING, IN_PROGRESS);

    public boolean canTransitionTo(CallStatus target) {
        return allowedTargets().contains(target);
    }

    private Set<CallStatus> allowedTargets() {
        return switch (this) {
            case PENDING -> Set.of(IN_PROGRESS, FAILED, EXPIRED);
            case IN_PROGRESS -> Set.of(ENDED, EXPIRED);
            case EXPIRED -> Set.of(ENDED);
            case ENDED, FAILED -> Set.of();
        };
    }

}
