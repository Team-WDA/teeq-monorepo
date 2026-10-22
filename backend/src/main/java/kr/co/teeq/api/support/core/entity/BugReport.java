package kr.co.teeq.api.support.core.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Embedded;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import kr.co.teeq.api.common.core.entity.BaseEntity;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.support.core.constant.BugReportSource;
import kr.co.teeq.api.support.core.constant.BugReportStatus;
import kr.co.teeq.api.support.core.model.BugReportEnvironment;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 회원이 앱에서(또는 개발자 콘솔에서) 남긴 버그 제보. 로그는 JSON 문자열로 저장하고 잘려 나간 개수를 따로 둔다.
 */
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
@Table(name = "bug_report")
public class BugReport extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "member_id", nullable = false)
    private Member member;

    @Column(nullable = false, columnDefinition = "text")
    private String content;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private BugReportStatus status;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private BugReportSource source;

    @Embedded
    private BugReportEnvironment environment;

    @Column(columnDefinition = "text")
    private String errorLogsJson;

    @Column(columnDefinition = "text")
    private String networkLogsJson;

    @Column(nullable = false)
    private int omittedErrorLogCount;

    @Column(nullable = false)
    private int omittedNetworkLogCount;

    private BugReport(
        Member member,
        BugReportSource source,
        String content,
        BugReportEnvironment environment,
        String errorLogsJson,
        String networkLogsJson,
        int omittedErrorLogCount,
        int omittedNetworkLogCount
    ) {
        this.member = member;
        this.source = source;
        this.content = content;
        this.status = BugReportStatus.RECEIVED;
        this.environment = environment;
        this.errorLogsJson = errorLogsJson;
        this.networkLogsJson = networkLogsJson;
        this.omittedErrorLogCount = omittedErrorLogCount;
        this.omittedNetworkLogCount = omittedNetworkLogCount;
    }

    public static BugReport of(
        Member member,
        BugReportSource source,
        String content,
        BugReportEnvironment environment,
        String errorLogsJson,
        String networkLogsJson,
        int omittedErrorLogCount,
        int omittedNetworkLogCount
    ) {
        return new BugReport(member, source, content, environment, errorLogsJson, networkLogsJson,
            omittedErrorLogCount, omittedNetworkLogCount);
    }

    public void changeStatus(BugReportStatus target) {
        if (!status.canTransitionTo(target)) {
            throw new CustomException(ErrorCode.STATE_CONFLICT);
        }
        this.status = target;
    }

}
