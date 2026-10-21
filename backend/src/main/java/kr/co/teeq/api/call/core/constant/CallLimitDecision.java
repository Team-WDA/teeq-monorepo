package kr.co.teeq.api.call.core.constant;

/**
 * 통화 시작 때의 한도 판정 결과. 허용 시간(초)과 그 값을 정한 한도의 종류를 담는다.
 */
public record CallLimitDecision(long allowedSeconds, LimitKind limitKind) {

    /**
     * 세 한도 중 가장 작은 값을 허용 시간으로 고른다. 값이 같으면 PER_DAY, WHOLE_SERVICE, PER_CALL 순으로 종류를 고른다.
     */
    public static CallLimitDecision of(long perCallSeconds, long perDayRemainingSeconds,
        long wholeServiceRemainingSeconds) {
        long allowedSeconds = Math.min(perCallSeconds, Math.min(perDayRemainingSeconds, wholeServiceRemainingSeconds));
        if (allowedSeconds == perDayRemainingSeconds) {
            return new CallLimitDecision(allowedSeconds, LimitKind.PER_DAY);
        }
        if (allowedSeconds == wholeServiceRemainingSeconds) {
            return new CallLimitDecision(allowedSeconds, LimitKind.WHOLE_SERVICE);
        }
        return new CallLimitDecision(allowedSeconds, LimitKind.PER_CALL);
    }

}
