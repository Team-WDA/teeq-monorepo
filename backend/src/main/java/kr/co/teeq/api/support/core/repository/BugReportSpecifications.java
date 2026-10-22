package kr.co.teeq.api.support.core.repository;

import kr.co.teeq.api.support.core.constant.BugReportSource;
import kr.co.teeq.api.support.core.constant.BugReportStatus;
import kr.co.teeq.api.support.core.entity.BugReport;
import org.springframework.data.jpa.domain.Specification;

/**
 * 관리자 버그 제보 목록 조회에 쓰는 검색 조건. 탈퇴 회원의 제보도 조회하므로 회원의 삭제 여부는 묻지 않는다.
 */
public final class BugReportSpecifications {

    private BugReportSpecifications() {
    }

    public static Specification<BugReport> notDeleted() {
        return (root, query, builder) -> builder.isFalse(root.<Boolean>get("deleted"));
    }

    public static Specification<BugReport> ofStatus(BugReportStatus status) {
        return (root, query, builder) -> builder.equal(root.get("status"), status);
    }

    public static Specification<BugReport> ofSource(BugReportSource source) {
        return (root, query, builder) -> builder.equal(root.get("source"), source);
    }

}
