package kr.co.teeq.api.support.core.entity;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.support.core.constant.BugReportPlatform;
import kr.co.teeq.api.support.core.constant.BugReportSource;
import kr.co.teeq.api.support.core.constant.BugReportStatus;
import kr.co.teeq.api.support.core.model.BugReportEnvironment;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class BugReportTest {

    private BugReport newBugReport() {
        Member member = Member.createSocialMember(LoginType.APPLE, "social-user-id", "member@teeq.co.kr");
        BugReportEnvironment environment =
            new BugReportEnvironment("1.0.0", BugReportPlatform.ANDROID, "Android 15", "Pixel 9");
        return BugReport.of(member, BugReportSource.USER, "통화가 끊깁니다", environment, "[]", "[]", 2, 3);
    }

    @Test
    @DisplayName("of로 만든 제보는 접수 상태로 시작하고 입력값을 보존한다")
    void of_startsAsReceived() {
        BugReport bugReport = newBugReport();

        assertThat(bugReport.getStatus()).isEqualTo(BugReportStatus.RECEIVED);
        assertThat(bugReport.getSource()).isEqualTo(BugReportSource.USER);
        assertThat(bugReport.getContent()).isEqualTo("통화가 끊깁니다");
        assertThat(bugReport.getEnvironment().platform()).isEqualTo(BugReportPlatform.ANDROID);
        assertThat(bugReport.getOmittedErrorLogCount()).isEqualTo(2);
        assertThat(bugReport.getOmittedNetworkLogCount()).isEqualTo(3);
    }

    @Test
    @DisplayName("다른 상태로 변경하면 상태가 바뀐다")
    void changeStatus_toDifferentStatus() {
        BugReport bugReport = newBugReport();

        bugReport.changeStatus(BugReportStatus.IN_PROGRESS);

        assertThat(bugReport.getStatus()).isEqualTo(BugReportStatus.IN_PROGRESS);
    }

    @Test
    @DisplayName("같은 상태로 변경하면 STATE_CONFLICT다")
    void changeStatus_toSameStatus() {
        BugReport bugReport = newBugReport();

        assertThatThrownBy(() -> bugReport.changeStatus(BugReportStatus.RECEIVED))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
    }

}
