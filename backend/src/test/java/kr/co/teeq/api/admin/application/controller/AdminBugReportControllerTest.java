package kr.co.teeq.api.admin.application.controller;

import static kr.co.teeq.api.admin.support.AdminTestAuthentication.asAdmin;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.view;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import kr.co.teeq.api.admin.infrastructure.config.AdminSecurityConfig;
import kr.co.teeq.api.admin.support.AdminSliceTestConfig;
import kr.co.teeq.api.common.application.exception.GlobalExceptionHandler;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.repository.AdminRepository;
import kr.co.teeq.api.support.application.dto.response.BugReportDetailResponse;
import kr.co.teeq.api.support.application.dto.response.BugReportErrorLogResponse;
import kr.co.teeq.api.support.application.dto.response.BugReportImageResponse;
import kr.co.teeq.api.support.application.dto.response.BugReportNetworkLogResponse;
import kr.co.teeq.api.support.application.dto.response.BugReportPageResponse;
import kr.co.teeq.api.support.application.dto.response.BugReportSummaryResponse;
import kr.co.teeq.api.support.application.service.BugReportCommandService;
import kr.co.teeq.api.support.application.service.BugReportQueryService;
import kr.co.teeq.api.support.core.constant.BugReportPlatform;
import kr.co.teeq.api.support.core.constant.BugReportSource;
import kr.co.teeq.api.support.core.constant.BugReportStatus;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.data.domain.Pageable;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(controllers = AdminBugReportController.class)
@ActiveProfiles("test")
@Import({
    AdminSecurityConfig.class,
    AdminSliceTestConfig.class,
    GlobalExceptionHandler.class,
    AdminExceptionHandler.class,
    AdminBugReportController.class
})
class AdminBugReportControllerTest {

    private static final UUID BUG_REPORT_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5c");
    private static final Instant LOGGED_AT = Instant.parse("2026-10-22T03:00:00Z");
    private static final String PATH = "/admin/bug-reports";
    private static final String HTMX_HEADER = "HX-Request";
    private static final String MARKUP = "<script>alert('x')</script>";
    private static final String ESCAPED_MARKUP = "&lt;script&gt;alert(&#39;x&#39;)&lt;/script&gt;";

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AdminRepository adminRepository;

    @MockitoBean
    private BugReportQueryService bugReportQueryService;

    @MockitoBean
    private BugReportCommandService bugReportCommandService;

    private BugReportSummaryResponse summary(BugReportSource source, boolean memberDeleted) {
        return new BugReportSummaryResponse(BUG_REPORT_ID, "앱이 멈춰요", BugReportStatus.RECEIVED, source,
            "a@teeq.com", memberDeleted, LOGGED_AT);
    }

    private BugReportDetailResponse detail(
        String content, List<BugReportErrorLogResponse> errorLogs, int omittedErrorLogCount, boolean memberDeleted) {
        return new BugReportDetailResponse(BUG_REPORT_ID, content, BugReportStatus.IN_PROGRESS,
            BugReportSource.DEVELOPER_CONSOLE, LOGGED_AT, "1.2.3", BugReportPlatform.ANDROID, "Android 15", "Pixel 9",
            MEMBER_ID, "a@teeq.com", "소연", memberDeleted,
            List.of(new BugReportImageResponse("https://cdn.example/k1.png")), errorLogs,
            List.of(new BugReportNetworkLogResponse(LOGGED_AT, "GET", "https://api.teeq.co.kr/x", Map.of("a", "b"),
                null, false, 500, Map.of(), MARKUP, true, 12, null)),
            omittedErrorLogCount, 0);
    }

    private BugReportErrorLogResponse errorLog(String message) {
        return new BugReportErrorLogResponse(LOGGED_AT, "SEVERE", "FlutterError", message, null, "stack-line");
    }

    @Test
    void list_rendersRowsWithBadgesAndKeepsFilters() throws Exception {
        given(bugReportQueryService.search(any(), any(), any())).willReturn(
            new BugReportPageResponse(List.of(summary(BugReportSource.DEVELOPER_CONSOLE, true)), 1, 20, 41));

        mockMvc.perform(get(PATH).with(asAdmin())
                .param("status", "RECEIVED").param("source", "DEVELOPER_CONSOLE").param("page", "1"))
            .andExpect(status().isOk())
            .andExpect(view().name("admin/bug-reports"))
            .andExpect(content().string(containsString("a@teeq.com")))
            .andExpect(content().string(containsString("탈퇴")))
            // 탈퇴 회원 상세는 404이므로 링크 없이 이메일만 보인다
            .andExpect(content().string(not(containsString("/admin/members/"))))
            .andExpect(content().string(containsString("개발자 콘솔")))
            .andExpect(content().string(containsString("2026-10-22 12:00:00")))
            .andExpect(content().string(containsString("href=\"/admin/bug-reports/" + BUG_REPORT_ID + "\"")))
            .andExpect(content().string(containsString("<option value=\"RECEIVED\" selected")))
            .andExpect(content().string(containsString("<option value=\"DEVELOPER_CONSOLE\" selected")))
            .andExpect(content().string(containsString("2 / 3")))
            .andExpect(content().string(containsString(
                "href=\"/admin/bug-reports?status=RECEIVED&amp;source=DEVELOPER_CONSOLE&amp;page=0&amp;size=20\"")));

        ArgumentCaptor<Pageable> pageable = ArgumentCaptor.forClass(Pageable.class);
        verify(bugReportQueryService).search(
            eq(BugReportStatus.RECEIVED), eq(BugReportSource.DEVELOPER_CONSOLE), pageable.capture());
        assertThat(pageable.getValue().getPageNumber()).isEqualTo(1);
    }

    @Test
    void list_userSourceWithActiveMember_showsGeneralBadgeWithoutWithdrawnBadge() throws Exception {
        given(bugReportQueryService.search(any(), any(), any()))
            .willReturn(new BugReportPageResponse(List.of(summary(BugReportSource.USER, false)), 0, 20, 1));

        mockMvc.perform(get(PATH).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("일반")))
            .andExpect(content().string(not(containsString("탈퇴"))));
        verify(bugReportQueryService).search(eq(null), eq(null), any());
    }

    @Test
    void list_empty_showsEmptyMessage() throws Exception {
        given(bugReportQueryService.search(any(), any(), any()))
            .willReturn(new BugReportPageResponse(List.of(), 0, 20, 0));

        mockMvc.perform(get(PATH).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("버그 제보가 없습니다")));
    }

    @Test
    void list_withInvalidStatus_showsErrorPage() throws Exception {
        mockMvc.perform(get(PATH).with(asAdmin()).param("status", "NOPE"))
            .andExpect(status().isBadRequest())
            .andExpect(view().name("admin/error"));

        verify(bugReportQueryService, never()).search(any(), any(), any());
    }

    @Test
    void detail_rendersImagesLogsAndOmittedNoteEscaped() throws Exception {
        given(bugReportQueryService.getDetail(BUG_REPORT_ID))
            .willReturn(detail(MARKUP, List.of(errorLog(MARKUP)), 3, true));

        mockMvc.perform(get(PATH + "/" + BUG_REPORT_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(view().name("admin/bug-report-detail"))
            // 본문과 로그 문자열은 이스케이프되어 보인다
            .andExpect(content().string(containsString(ESCAPED_MARKUP)))
            .andExpect(content().string(not(containsString(MARKUP))))
            .andExpect(content().string(containsString("FlutterError")))
            .andExpect(content().string(containsString("https://api.teeq.co.kr/x")))
            // 이미지는 썸네일이고 새 탭 원본 링크다
            .andExpect(content().string(containsString("href=\"https://cdn.example/k1.png\"")))
            .andExpect(content().string(containsString("target=\"_blank\"")))
            // 에러 로그 1건 + 제외 3건 = 4건 중 1건만 첨부됨
            .andExpect(content().string(containsString("4건 중 1건만 첨부됨")))
            .andExpect(content().string(containsString("a@teeq.com")))
            .andExpect(content().string(containsString("탈퇴")))
            .andExpect(content().string(containsString("개발자 콘솔")))
            .andExpect(content().string(containsString("Pixel 9")))
            // 상태 변경 폼
            .andExpect(content().string(containsString("hx-post=\"/admin/bug-reports/" + BUG_REPORT_ID + "/status\"")));
    }

    @Test
    void detail_userSourceReport_hidesLogPanels() throws Exception {
        BugReportDetailResponse developerConsoleDetail = detail("본문", List.of(), 0, false);
        BugReportDetailResponse userDetail = new BugReportDetailResponse(developerConsoleDetail.id(),
            developerConsoleDetail.content(), developerConsoleDetail.status(), BugReportSource.USER,
            developerConsoleDetail.createdAt(), developerConsoleDetail.appVersion(), developerConsoleDetail.platform(),
            developerConsoleDetail.osVersion(), developerConsoleDetail.deviceModel(), developerConsoleDetail.memberId(),
            developerConsoleDetail.memberEmail(), developerConsoleDetail.memberNickname(), false,
            developerConsoleDetail.images(), List.of(), List.of(), 0, 0);
        given(bugReportQueryService.getDetail(BUG_REPORT_ID)).willReturn(userDetail);

        mockMvc.perform(get(PATH + "/" + BUG_REPORT_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("제보 내용")))
            .andExpect(content().string(not(containsString("에러 로그"))))
            .andExpect(content().string(not(containsString("네트워크 기록"))));
    }

    @Test
    void detail_developerConsoleReport_showsLogPanelHeadings() throws Exception {
        given(bugReportQueryService.getDetail(BUG_REPORT_ID)).willReturn(detail("본문", List.of(), 0, false));

        mockMvc.perform(get(PATH + "/" + BUG_REPORT_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("에러 로그")))
            .andExpect(content().string(containsString("네트워크 기록")));
    }

    @Test
    void detail_withoutOmittedLogs_hidesOmittedNote() throws Exception {
        given(bugReportQueryService.getDetail(BUG_REPORT_ID))
            .willReturn(detail("본문", List.of(errorLog("메시지")), 0, false));

        mockMvc.perform(get(PATH + "/" + BUG_REPORT_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(not(containsString("건만 첨부됨"))))
            .andExpect(content().string(containsString("/admin/members/" + MEMBER_ID)))
            .andExpect(content().string(not(containsString("탈퇴"))));
    }

    @Test
    void detail_unknownId_showsNotFoundPage() throws Exception {
        given(bugReportQueryService.getDetail(BUG_REPORT_ID))
            .willThrow(new CustomException(ErrorCode.BUG_REPORT_NOT_FOUND));

        mockMvc.perform(get(PATH + "/" + BUG_REPORT_ID).with(asAdmin()))
            .andExpect(status().isNotFound())
            .andExpect(view().name("admin/error"))
            .andExpect(content().string(containsString(ErrorCode.BUG_REPORT_NOT_FOUND.message())));
    }

    @Test
    void changeStatus_returnsStatusFormFragment() throws Exception {
        given(bugReportCommandService.changeStatus(BUG_REPORT_ID, BugReportStatus.RESOLVED))
            .willReturn(BugReportStatus.RESOLVED);

        mockMvc.perform(post(PATH + "/" + BUG_REPORT_ID + "/status")
                .header(HTMX_HEADER, "true").with(asAdmin()).with(csrf()).param("status", "RESOLVED"))
            .andExpect(status().isOk())
            // 현재 상태는 배지로 보이고, 선택지에서는 빠진다
            .andExpect(content().string(containsString("badge-success")))
            .andExpect(content().string(not(containsString("<option value=\"RESOLVED\""))))
            .andExpect(content().string(containsString("<option value=\"RECEIVED\"")))
            .andExpect(content().string(containsString("<option value=\"IN_PROGRESS\"")))
            .andExpect(content().string(not(containsString("<html"))));

        verify(bugReportCommandService).changeStatus(BUG_REPORT_ID, BugReportStatus.RESOLVED);
    }

    @Test
    void changeStatus_sameStatus_showsStateConflict() throws Exception {
        given(bugReportCommandService.changeStatus(BUG_REPORT_ID, BugReportStatus.RECEIVED))
            .willThrow(new CustomException(ErrorCode.STATE_CONFLICT));

        mockMvc.perform(post(PATH + "/" + BUG_REPORT_ID + "/status")
                .header(HTMX_HEADER, "true").with(asAdmin()).with(csrf()).param("status", "RECEIVED"))
            .andExpect(status().isConflict())
            .andExpect(content().string(containsString(ErrorCode.STATE_CONFLICT.message())));
    }

    @Test
    void changeStatus_withInvalidStatus_showsErrorPageWithoutCallingService() throws Exception {
        mockMvc.perform(post(PATH + "/" + BUG_REPORT_ID + "/status")
                .with(asAdmin()).with(csrf()).param("status", "NOPE"))
            .andExpect(status().isBadRequest());

        verify(bugReportCommandService, never()).changeStatus(any(), any());
    }

    @Test
    void changeStatus_withoutCsrf_isForbidden() throws Exception {
        given(bugReportQueryService.getDetail(BUG_REPORT_ID))
            .willReturn(detail("본문", List.of(), 0, false));
        // 화면을 열어 CSRF 토큰이 저장된 세션에서 토큰 없이 보내면 잘못된 토큰으로 판정된다
        MockHttpSession session = (MockHttpSession) mockMvc.perform(get(PATH + "/" + BUG_REPORT_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andReturn().getRequest().getSession(false);

        mockMvc.perform(post(PATH + "/" + BUG_REPORT_ID + "/status")
                .session(session).with(asAdmin()).param("status", "RESOLVED"))
            .andExpect(status().isForbidden());

        verify(bugReportCommandService, never()).changeStatus(any(), any());
    }

}
