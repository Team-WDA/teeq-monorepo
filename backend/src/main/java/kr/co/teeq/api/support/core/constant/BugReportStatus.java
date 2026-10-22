package kr.co.teeq.api.support.core.constant;

/**
 * 버그 제보의 처리 상태. 관리자가 서로 다른 상태로 자유롭게 바꿀 수 있다.
 */
public enum BugReportStatus {
    RECEIVED,
    IN_PROGRESS,
    RESOLVED;

    public boolean canTransitionTo(BugReportStatus target) {
        return this != target;
    }

}
