package kr.co.teeq.api.call.core.constant;

/**
 * 하루 추가 통화 시간 부여 규칙. 요청 검증과 API 문서가 같은 값을 참조한다.
 */
public final class CallBonusPolicy {

    public static final int MIN_SECONDS = 1;
    public static final int MAX_SECONDS = 3600;
    public static final int MAX_REASON_LENGTH = 200;

    private CallBonusPolicy() {
    }

}
