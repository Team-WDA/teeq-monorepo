package kr.co.teeq.api.support.core.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import kr.co.teeq.api.common.core.entity.BaseEntity;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 버그 제보에 첨부된 이미지 메타데이터. 파일 자체는 저장소에 두고 DB에는 저장 키만 둔다.
 */
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
@Table(name = "bug_report_image")
public class BugReportImage extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "bug_report_id", nullable = false)
    private BugReport bugReport;

    @Column(nullable = false, length = 100)
    private String storageKey;

    @Column(nullable = false, length = 50)
    private String contentType;

    @Column(nullable = false)
    private long fileSize;

    @Column(nullable = false)
    private int sortOrder;

    private BugReportImage(BugReport bugReport, String storageKey, String contentType, long fileSize, int sortOrder) {
        this.bugReport = bugReport;
        this.storageKey = storageKey;
        this.contentType = contentType;
        this.fileSize = fileSize;
        this.sortOrder = sortOrder;
    }

    public static BugReportImage of(
        BugReport bugReport,
        String storageKey,
        String contentType,
        long fileSize,
        int sortOrder
    ) {
        return new BugReportImage(bugReport, storageKey, contentType, fileSize, sortOrder);
    }

}
