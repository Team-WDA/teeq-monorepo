package kr.co.teeq.api.support.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.tuple;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verify;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.media.core.model.StoredMedia;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.support.application.dto.request.BugReportCreateRequest;
import kr.co.teeq.api.support.application.dto.request.BugReportEnvironmentRequest;
import kr.co.teeq.api.support.core.constant.BugReportPlatform;
import kr.co.teeq.api.support.core.constant.BugReportSource;
import kr.co.teeq.api.support.core.constant.BugReportStatus;
import kr.co.teeq.api.support.core.entity.BugReport;
import kr.co.teeq.api.support.core.entity.BugReportImage;
import kr.co.teeq.api.support.core.model.BugReportEnvironment;
import kr.co.teeq.api.support.core.repository.BugReportImageRepository;
import kr.co.teeq.api.support.core.repository.BugReportRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class BugReportCommandServiceTest {

    private static final UUID BUG_REPORT_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");

    @Mock
    private BugReportRepository bugReportRepository;
    @Mock
    private BugReportImageRepository bugReportImageRepository;
    @InjectMocks
    private BugReportCommandService bugReportCommandService;

    private final Member member = Member.createMember(LoginType.GOOGLE, "google-uid", "a@teeq.com", "소연");

    private BugReportCreateRequest request() {
        return new BugReportCreateRequest(BugReportSource.USER, "앱이 멈춰요",
            new BugReportEnvironmentRequest("1.2.3", BugReportPlatform.IOS, "iOS 19", "iPhone 17"),
            null, null, 0, 0);
    }

    private void stubSaveWithId() {
        given(bugReportRepository.save(any(BugReport.class))).willAnswer(invocation -> {
            BugReport saved = invocation.getArgument(0);
            ReflectionTestUtils.setField(saved, "id", BUG_REPORT_ID);
            return saved;
        });
    }

    @Test
    void save_assignsSortOrderInInputOrderStartingFromZero() {
        stubSaveWithId();
        List<StoredMedia> images = List.of(
            new StoredMedia("k1.png", "image/png", 10), new StoredMedia("k2.jpg", "image/jpeg", 20));

        UUID bugReportId = bugReportCommandService.save(member, request(), null, null, images);

        assertThat(bugReportId).isEqualTo(BUG_REPORT_ID);
        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<BugReportImage>> captor = ArgumentCaptor.forClass(List.class);
        verify(bugReportImageRepository).saveAll(captor.capture());
        assertThat(captor.getValue())
            .extracting(BugReportImage::getStorageKey, BugReportImage::getContentType,
                BugReportImage::getFileSize, BugReportImage::getSortOrder)
            .containsExactly(tuple("k1.png", "image/png", 10L, 0), tuple("k2.jpg", "image/jpeg", 20L, 1));
    }

    @Test
    void save_withoutLogs_keepsJsonColumnsNullAndCountsZero() {
        stubSaveWithId();

        bugReportCommandService.save(member, request(), null, null, List.of());

        ArgumentCaptor<BugReport> captor = ArgumentCaptor.forClass(BugReport.class);
        verify(bugReportRepository).save(captor.capture());
        BugReport saved = captor.getValue();
        assertThat(saved.getErrorLogsJson()).isNull();
        assertThat(saved.getNetworkLogsJson()).isNull();
        assertThat(saved.getOmittedErrorLogCount()).isZero();
        assertThat(saved.getOmittedNetworkLogCount()).isZero();
        assertThat(saved.getStatus()).isEqualTo(BugReportStatus.RECEIVED);
        assertThat(saved.getContent()).isEqualTo("앱이 멈춰요");
        assertThat(saved.getEnvironment().appVersion()).isEqualTo("1.2.3");
    }

    private BugReport receivedBugReport() {
        return BugReport.of(member, BugReportSource.USER, "본문",
            new BugReportEnvironment("1.2.3", BugReportPlatform.IOS, "iOS 19", "iPhone 17"), null, null, 0, 0);
    }

    @Test
    void changeStatus_differentStatus_updatesAndReturnsIt() {
        BugReport bugReport = receivedBugReport();
        given(bugReportRepository.findDetailByIdAndDeletedFalse(BUG_REPORT_ID)).willReturn(Optional.of(bugReport));

        BugReportStatus changed = bugReportCommandService.changeStatus(BUG_REPORT_ID, BugReportStatus.IN_PROGRESS);

        assertThat(changed).isEqualTo(BugReportStatus.IN_PROGRESS);
        assertThat(bugReport.getStatus()).isEqualTo(BugReportStatus.IN_PROGRESS);
    }

    @Test
    void changeStatus_sameStatus_throwsStateConflict() {
        given(bugReportRepository.findDetailByIdAndDeletedFalse(BUG_REPORT_ID))
            .willReturn(Optional.of(receivedBugReport()));

        assertThatThrownBy(() -> bugReportCommandService.changeStatus(BUG_REPORT_ID, BugReportStatus.RECEIVED))
            .isInstanceOf(CustomException.class)
            .extracting(exception -> ((CustomException) exception).getErrorCode())
            .isEqualTo(ErrorCode.STATE_CONFLICT);
    }

    @Test
    void changeStatus_unknownId_throwsBugReportNotFound() {
        given(bugReportRepository.findDetailByIdAndDeletedFalse(BUG_REPORT_ID)).willReturn(Optional.empty());

        assertThatThrownBy(() -> bugReportCommandService.changeStatus(BUG_REPORT_ID, BugReportStatus.RESOLVED))
            .isInstanceOf(CustomException.class)
            .extracting(exception -> ((CustomException) exception).getErrorCode())
            .isEqualTo(ErrorCode.BUG_REPORT_NOT_FOUND);
    }

}
