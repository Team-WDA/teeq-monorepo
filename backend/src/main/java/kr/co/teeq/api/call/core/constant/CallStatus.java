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
