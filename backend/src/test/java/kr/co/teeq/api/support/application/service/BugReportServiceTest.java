package kr.co.teeq.api.support.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

import java.time.Instant;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.media.application.service.MediaService;
import kr.co.teeq.api.media.core.constant.MediaCategory;
import kr.co.teeq.api.media.core.model.StoredMedia;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.support.application.dto.request.BugReportCreateRequest;
import kr.co.teeq.api.support.application.dto.request.BugReportEnvironmentRequest;
import kr.co.teeq.api.support.application.dto.request.BugReportErrorLogRequest;
import kr.co.teeq.api.support.application.dto.request.BugReportNetworkLogRequest;
import kr.co.teeq.api.support.application.dto.response.BugReportCreateResponse;
import kr.co.teeq.api.support.core.constant.BugReportPlatform;
import kr.co.teeq.api.support.core.constant.BugReportSource;
import kr.co.teeq.api.support.core.port.BugReportNotification;
import kr.co.teeq.api.support.core.port.BugReportNotificationPort;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InOrder;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.multipart.MultipartFile;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.json.JsonMapper;

@ExtendWith(MockitoExtension.class)
class BugReportServiceTest {

    private static final UUID BUG_REPORT_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final Instant LOGGED_AT = Instant.parse("2026-10-22T00:00:00Z");
    private static final BugReportEnvironmentRequest ENVIRONMENT =
        new BugReportEnvironmentRequest("1.2.3", BugReportPlatform.ANDROID, "Android 15", "Pixel 9");

    @Mock
    private MediaService mediaService;
    @Mock
    private BugReportCommandService bugReportCommandService;
    @Mock
    private BugReportNotificationPort bugReportNotificationPort;

    private final ObjectMapper objectMapper = JsonMapper.builder().build();
    private final Member member = Member.createMember(LoginType.GOOGLE, "google-uid", "a@teeq.com", "소연");

    private BugReportService bugReportService;

    @BeforeEach
    void setUp() {
        bugReportService = new BugReportService(
            mediaService, bugReportCommandService, bugReportNotificationPort, objectMapper);
    }

    private BugReportErrorLogRequest errorLog(String message) {
        return new BugReportErrorLogRequest(LOGGED_AT, "SEVERE", "name", message, null, null);
    }

    private BugReportNetworkLogRequest networkLog() {
        return new BugReportNetworkLogRequest(LOGGED_AT, "GET", "https://api.teeq.co.kr/x",
            Map.of(), null, false, 200, Map.of(), null, false, 10, null);
    }

    private BugReportCreateRequest request(
        BugReportSource source,
        List<BugReportErrorLogRequest> errorLogs,
        List<BugReportNetworkLogRequest> networkLogs
    ) {
        return new BugReportCreateRequest(source, "앱이 멈춰요", ENVIRONMENT, errorLogs, networkLogs, 0, 0);
    }

    private BugReportCreateRequest userRequest() {
        return request(BugReportSource.USER, null, null);
    }

    private List<MultipartFile> images(int count) {
        MultipartFile file = new MockMultipartFile("images", "a.png", "image/png", new byte[] {1});
        return Collections.nCopies(count, file);
    }

    private void assertErrorCode(Runnable action, ErrorCode errorCode) {
        assertThatThrownBy(action::run)
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(errorCode));
    }

    @Test
    void create_userSourceWithLogs_throwsInvalidRequest() {
        BugReportCreateRequest request = request(BugReportSource.USER, List.of(errorLog("e")), null);

        assertErrorCode(() -> bugReportService.create(member, request, List.of()), ErrorCode.INVALID_REQUEST);
        verifyNoInteractions(mediaService, bugReportCommandService, bugReportNotificationPort);
    }

    @Test
    void create_sixImages_throwsTooManyAndStoresNothing() {
        assertErrorCode(
            () -> bugReportService.create(member, userRequest(), images(6)), ErrorCode.BUG_REPORT_IMAGE_TOO_MANY);
        verifyNoInteractions(mediaService, bugReportCommandService);
    }

    @Test
    void create_logsOverFiveMegabytes_throwsInvalidRequest() {
        // 항목당 약 100KB씩 60건이면 5MB를 넘는다
        List<BugReportErrorLogRequest> errorLogs = Collections.nCopies(60, errorLog("a".repeat(100 * 1024)));
        BugReportCreateRequest request = request(BugReportSource.DEVELOPER_CONSOLE, errorLogs, null);

        assertErrorCode(() -> bugReportService.create(member, request, List.of()), ErrorCode.INVALID_REQUEST);
        verifyNoInteractions(mediaService, bugReportCommandService);
    }

    @Test
    void create_moreThanOneHundredLogEntries_throwsInvalidRequest() {
        List<BugReportNetworkLogRequest> networkLogs = Collections.nCopies(101, networkLog());
        BugReportCreateRequest request = request(BugReportSource.DEVELOPER_CONSOLE, null, networkLogs);

        assertErrorCode(() -> bugReportService.create(member, request, List.of()), ErrorCode.INVALID_REQUEST);
        verifyNoInteractions(mediaService, bugReportCommandService);
    }

    @Test
    void create_saveFailure_deletesUploadedImages() {
        List<MultipartFile> files = images(2);
        List<StoredMedia> stored = List.of(
            new StoredMedia("k1.png", "image/png", 1), new StoredMedia("k2.png", "image/png", 1));
        given(mediaService.storeImages(MediaCategory.BUG_REPORT_IMAGE, files)).willReturn(stored);
        RuntimeException failure = new IllegalStateException("db down");
        given(bugReportCommandService.save(eq(member), any(), any(), any(), eq(stored))).willThrow(failure);

        assertThatThrownBy(() -> bugReportService.create(member, userRequest(), files)).isSameAs(failure);

        verify(mediaService).deleteAll(MediaCategory.BUG_REPORT_IMAGE, List.of("k1.png", "k2.png"));
        verifyNoInteractions(bugReportNotificationPort);
    }

    @Test
    void create_notificationFailure_stillReturnsResponse() {
        given(mediaService.storeImages(eq(MediaCategory.BUG_REPORT_IMAGE), anyList())).willReturn(List.of());
        given(bugReportCommandService.save(any(), any(), any(), any(), anyList())).willReturn(BUG_REPORT_ID);
        org.mockito.BDDMockito.willThrow(new IllegalStateException("discord down"))
            .given(bugReportNotificationPort).notify(any());

        BugReportCreateResponse response = bugReportService.create(member, userRequest(), null);

        assertThat(response.bugReportId()).isEqualTo(BUG_REPORT_ID);
        verify(mediaService, never()).deleteAll(any(), anyList());
    }

    @Test
    void create_success_notifiesAfterSave() {
        given(mediaService.storeImages(eq(MediaCategory.BUG_REPORT_IMAGE), anyList())).willReturn(List.of());
        given(bugReportCommandService.save(any(), any(), any(), any(), anyList())).willReturn(BUG_REPORT_ID);

        BugReportCreateResponse response = bugReportService.create(member, userRequest(), List.of());

        assertThat(response.bugReportId()).isEqualTo(BUG_REPORT_ID);
        InOrder inOrder = inOrder(bugReportCommandService, bugReportNotificationPort);
        inOrder.verify(bugReportCommandService).save(eq(member), any(), eq(null), eq(null), anyList());
        inOrder.verify(bugReportNotificationPort).notify(new BugReportNotification(
            BUG_REPORT_ID, BugReportSource.USER, "앱이 멈춰요", "1.2.3", BugReportPlatform.ANDROID));
    }

    @Test
    void create_developerConsoleLogs_savesReserializedJson() {
        given(mediaService.storeImages(eq(MediaCategory.BUG_REPORT_IMAGE), anyList())).willReturn(List.of());
        given(bugReportCommandService.save(any(), any(), any(), any(), anyList())).willReturn(BUG_REPORT_ID);
        BugReportCreateRequest request = request(
            BugReportSource.DEVELOPER_CONSOLE, List.of(errorLog("boom")), List.of(networkLog()));

        bugReportService.create(member, request, List.of());

        ArgumentCaptor<String> errorLogsJson = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<String> networkLogsJson = ArgumentCaptor.forClass(String.class);
        verify(bugReportCommandService).save(
            eq(member), eq(request), errorLogsJson.capture(), networkLogsJson.capture(), anyList());
        assertThat(errorLogsJson.getValue()).contains("\"message\":\"boom\"").contains("2026-10-22T00:00:00Z");
        assertThat(networkLogsJson.getValue()).contains("\"statusCode\":200");
    }

}
