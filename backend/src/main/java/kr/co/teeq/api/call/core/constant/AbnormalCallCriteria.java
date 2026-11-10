package kr.co.teeq.api.call.core.constant;

import java.util.List;

/**
 * 비정상 통화의 정의. 시작 실패·만료이거나, 종료됐지만 사유가 에이전트 오류·배정 실패인 통화다.
 * 목록 검색 조건과 기간별 집계 쿼리가 같은 기준을 쓰도록 한 곳에 둔다.
 */
public final class AbnormalCallCriteria {

    public static final List<CallStatus> STATUSES = List.of(CallStatus.FAILED, CallStatus.EXPIRED);

    // 상태가 ENDED일 때 비정상으로 보는 종료 사유
    public static final List<EndReason> ENDED_END_REASONS = List.of(EndReason.AGENT_ERROR, EndReason.DISPATCH_FAILED);

    private AbnormalCallCriteria() {
    }

    // 네이티브 쿼리에 넘기는 상태 이름(문자열 저장 값)
    public static List<String> statusNames() {
        return STATUSES.stream().map(Enum::name).toList();
    }

    // 네이티브 쿼리에 넘기는 종료 사유 이름(문자열 저장 값)
    public static List<String> endedEndReasonNames() {
        return ENDED_END_REASONS.stream().map(Enum::name).toList();
    }

}
