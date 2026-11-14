package kr.co.teeq.api.admin.application.view;

import kr.co.teeq.api.call.core.constant.CallStatus;
import kr.co.teeq.api.call.core.constant.EndReason;

/**
 * 관리자 화면에 보여 주는 통화 상태·종료 사유의 한국어 라벨.
 * switch 식으로 enum 전수를 처리해 값이 추가되면 컴파일 오류가 나게 한다.
 */
public final class CallDisplayLabel {

    private static final String EMPTY_LABEL = "-";

    private CallDisplayLabel() {
    }

    public static String status(CallStatus status) {
        return switch (status) {
            case PENDING -> "대기 중";
            case IN_PROGRESS -> "통화 중";
            case ENDED -> "종료";
            case FAILED -> "시작 실패";
            case EXPIRED -> "만료";
            case CANCELLED -> "취소";
        };
    }

    // 종료 사유가 없으면 "-"
    public static String endReason(EndReason endReason) {
        if (endReason == null) {
            return EMPTY_LABEL;
        }
        return switch (endReason) {
            case USER_HANGUP -> "사용자 종료";
            case USER_DISCONNECTED -> "연결 끊김";
            case LIMIT_REACHED -> "시간 한도 도달";
            case AGENT_ERROR -> "에이전트 오류";
            case DISPATCH_FAILED -> "에이전트 배정 실패";
        };
    }

}
