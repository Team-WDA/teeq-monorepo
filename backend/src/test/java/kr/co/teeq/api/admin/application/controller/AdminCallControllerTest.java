package kr.co.teeq.api.admin.application.controller;

import static kr.co.teeq.api.admin.support.AdminTestAuthentication.asAdmin;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.view;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.admin.application.dto.response.AdminCallDetailResponse;
import kr.co.teeq.api.admin.application.dto.response.AdminCallDetailResponse.ConversationState;
import kr.co.teeq.api.admin.application.service.AdminCallDetailService;
import kr.co.teeq.api.admin.infrastructure.config.AdminSecurityConfig;
import kr.co.teeq.api.admin.support.AdminSliceTestConfig;
import kr.co.teeq.api.call.application.dto.request.CallHistorySearchRequest;
import kr.co.teeq.api.call.application.dto.response.CallHistoryItemResponse;
import kr.co.teeq.api.call.application.dto.response.CallHistoryPageResponse;
import kr.co.teeq.api.call.application.service.CallHistoryQueryService;
import kr.co.teeq.api.call.core.constant.CallStatus;
import kr.co.teeq.api.call.core.constant.EndReason;
import kr.co.teeq.api.call.core.port.AiCallDetail;
import kr.co.teeq.api.call.core.port.AiCallTurn;
import kr.co.teeq.api.call.core.port.AiCallTurnRole;
import kr.co.teeq.api.common.application.exception.GlobalExceptionHandler;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.repository.AdminRepository;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(controllers = AdminCallController.class)
@ActiveProfiles("test")
@Import({
    AdminSecurityConfig.class,
    AdminSliceTestConfig.class,
    GlobalExceptionHandler.class,
    AdminExceptionHandler.class,
    AdminCallController.class
})
class AdminCallControllerTest {

    private static final String PATH = "/admin/calls";
    private static final String SESSION_ID = "session-0001";
    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final CallHistorySearchRequest EMPTY_REQUEST =
        new CallHistorySearchRequest(null, null, null, null, null, false);

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AdminRepository adminRepository;

    @MockitoBean
    private CallHistoryQueryService callHistoryQueryService;

    @MockitoBean
    private AdminCallDetailService adminCallDetailService;

    @Test
    void calls_defaultRequest_passesEmptyRequestAndFirstPageAndRendersRows() throws Exception {
        given(callHistoryQueryService.search(any(), any())).willReturn(pageOf(List.of(endedCall(), pendingCall()),
            0, 20, 2));

        mockMvc.perform(get(PATH).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(view().name("admin/calls"))
            // 한국 시간 2026-10-20 12:00 시작, 날짜 구분 헤더와 행
            .andExpect(content().string(containsString("2026-10-20")))
            .andExpect(content().string(containsString("2026-10-20 12:00:00")))
            .andExpect(content().string(containsString("통화자")))
            .andExpect(content().string(containsString("foo@example.com")))
            .andExpect(content().string(containsString("종료")))
            .andExpect(content().string(containsString("대기 중")))
            .andExpect(content().string(containsString("사용자 종료")))
            // 사이드바의 통화 기록 링크
            .andExpect(content().string(containsString("href=\"/admin/calls\"")));

        ArgumentCaptor<Pageable> pageable = ArgumentCaptor.forClass(Pageable.class);
        verify(callHistoryQueryService).search(org.mockito.ArgumentMatchers.eq(EMPTY_REQUEST), pageable.capture());
        assertThat(pageable.getValue()).isEqualTo(PageRequest.of(0, 20));
    }

    @Test
    void calls_rowLinksToDetailOnlyWhenCallSessionIdExists() throws Exception {
        given(callHistoryQueryService.search(any(), any())).willReturn(pageOf(List.of(pendingCall()), 0, 20, 1));

        mockMvc.perform(get(PATH).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("대기 중")))
            .andExpect(content().string(not(containsString("/admin/calls/"))));

        given(callHistoryQueryService.search(any(), any())).willReturn(pageOf(List.of(endedCall()), 0, 20, 1));

        mockMvc.perform(get(PATH).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("href=\"/admin/calls/" + SESSION_ID + "\"")));
    }

    @Test
    void calls_withFilters_keepsFormValuesAndPassesRequest() throws Exception {
        given(callHistoryQueryService.search(any(), any())).willReturn(pageOf(List.of(), 0, 20, 0));

        mockMvc.perform(get(PATH).with(asAdmin())
                .param("keyword", "foo").param("from", "2026-10-01").param("to", "2026-10-31")
                .param("status", "ENDED").param("abnormalOnly", "true"))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("value=\"foo\"")))
            .andExpect(content().string(containsString("value=\"2026-10-01\"")))
            .andExpect(content().string(containsString("value=\"2026-10-31\"")))
            .andExpect(content().string(containsString("checked")))
            .andExpect(content().string(containsString("통화 기록이 없습니다.")));

        verify(callHistoryQueryService).search(
            org.mockito.ArgumentMatchers.eq(new CallHistorySearchRequest(null, "foo", LocalDate.of(2026, 10, 1),
                LocalDate.of(2026, 10, 31), CallStatus.ENDED, true)), any());
    }

    @Test
    void calls_middlePage_paginationLinksCarryOnlyFiltersWithValues() throws Exception {
        given(callHistoryQueryService.search(any(), any())).willReturn(pageOf(List.of(endedCall()), 1, 20, 50));

        mockMvc.perform(get(PATH).with(asAdmin()).param("keyword", "foo").param("page", "1").param("size", "1"))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("2 / 3")))
            .andExpect(content().string(containsString("/admin/calls?keyword=foo&amp;page=0\"")))
            .andExpect(content().string(containsString("/admin/calls?keyword=foo&amp;page=2\"")))
            .andExpect(content().string(not(containsString("size="))));

        ArgumentCaptor<Pageable> pageable = ArgumentCaptor.forClass(Pageable.class);
        verify(callHistoryQueryService).search(any(), pageable.capture());
        assertThat(pageable.getValue()).isEqualTo(PageRequest.of(1, 20));
    }

    @Test
    void calls_negativeAndHugePage_areClampedWithoutError() throws Exception {
        given(callHistoryQueryService.search(any(), any())).willReturn(pageOf(List.of(), 0, 20, 0));

        mockMvc.perform(get(PATH).with(asAdmin()).param("page", "-5")).andExpect(status().isOk());
        mockMvc.perform(get(PATH).with(asAdmin()).param("page", "2147483647")).andExpect(status().isOk());

        ArgumentCaptor<Pageable> pageable = ArgumentCaptor.forClass(Pageable.class);
        verify(callHistoryQueryService, org.mockito.Mockito.times(2)).search(any(), pageable.capture());
        assertThat(pageable.getAllValues().get(0)).isEqualTo(PageRequest.of(0, 20));
        assertThat(pageable.getAllValues().get(1)).isEqualTo(PageRequest.of(Integer.MAX_VALUE / 20, 20));
    }

    @Test
    void calls_malformedParameters_show400ErrorScreenWithoutCallingService() throws Exception {
        mockMvc.perform(get(PATH).with(asAdmin()).param("status", "XYZ"))
            .andExpect(status().isBadRequest()).andExpect(view().name("admin/error"));
        mockMvc.perform(get(PATH).with(asAdmin()).param("from", "2026-13-45"))
            .andExpect(status().isBadRequest()).andExpect(view().name("admin/error"));
        mockMvc.perform(get(PATH).with(asAdmin()).param("page", "abc"))
            .andExpect(status().isBadRequest()).andExpect(view().name("admin/error"));

        verify(callHistoryQueryService, never()).search(any(), any());
    }

    @Test
    void detail_loaded_rendersCallInfoSummaryConversationAndCost() throws Exception {
        AiCallDetail aiDetail = new AiCallDetail(SESSION_ID, "오늘 하루를 이야기했다", "gpt-test",
            new BigDecimal("0.0123"), true, List.of(
                new AiCallTurn(0, AiCallTurnRole.USER, "안녕하세요", false, 800, 300),
                new AiCallTurn(1, AiCallTurnRole.ASSISTANT, "반가워요", true, 900, 350)));
        given(adminCallDetailService.getDetail(SESSION_ID))
            .willReturn(new AdminCallDetailResponse(endedCall(), ConversationState.LOADED, aiDetail));

        mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(view().name("admin/call-detail"))
            .andExpect(content().string(containsString("2026-10-20 12:00:00")))
            .andExpect(content().string(containsString("사용자 종료")))
            .andExpect(content().string(containsString("오늘 하루를 이야기했다")))
            .andExpect(content().string(containsString("안녕하세요")))
            .andExpect(content().string(containsString("반가워요")))
            .andExpect(content().string(containsString("끼어듦")))
            .andExpect(content().string(containsString("0.0123")))
            .andExpect(content().string(containsString("gpt-test")))
            .andExpect(content().string(containsString("<details")))
            .andExpect(content().string(not(containsString("대화를 불러오지 못했습니다"))));
    }

    @Test
    void detail_loadedWithNullOptionalFields_showsDash() throws Exception {
        AiCallDetail aiDetail = new AiCallDetail(SESSION_ID, null, null, null, null, List.of(
            new AiCallTurn(0, AiCallTurnRole.USER, "안녕하세요", false, null, null)));
        given(adminCallDetailService.getDetail(SESSION_ID))
            .willReturn(new AdminCallDetailResponse(endedCall(), ConversationState.LOADED, aiDetail));

        mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("안녕하세요")));
    }

    @Test
    void detail_expired_showsExpiredNotice() throws Exception {
        given(adminCallDetailService.getDetail(SESSION_ID))
            .willReturn(new AdminCallDetailResponse(endedCall(), ConversationState.EXPIRED, null));

        mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("보관 기간이 지나 대화가 삭제되었습니다")));
    }

    @Test
    void detail_notRecorded_showsNotRecordedNotice() throws Exception {
        given(adminCallDetailService.getDetail(SESSION_ID))
            .willReturn(new AdminCallDetailResponse(endedCall(), ConversationState.NOT_RECORDED, null));

        mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("AI 서버에 기록이 없습니다")));
    }

    @Test
    void detail_unavailable_showsCallInfoAndRetryLink() throws Exception {
        given(adminCallDetailService.getDetail(SESSION_ID))
            .willReturn(new AdminCallDetailResponse(endedCall(), ConversationState.UNAVAILABLE, null));

        mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("대화를 불러오지 못했습니다")))
            .andExpect(content().string(containsString("다시 시도")))
            .andExpect(content().string(containsString("href=\"/admin/calls/" + SESSION_ID + "\"")))
            .andExpect(content().string(containsString("2026-10-20 12:00:00")))
            .andExpect(content().string(containsString("사용자 종료")));
    }

    @Test
    void detail_conversationText_isEscaped() throws Exception {
        AiCallDetail aiDetail = new AiCallDetail(SESSION_ID, null, null, null, null, List.of(
            new AiCallTurn(0, AiCallTurnRole.USER, "<script>alert(1)</script>", false, null, null)));
        given(adminCallDetailService.getDetail(SESSION_ID))
            .willReturn(new AdminCallDetailResponse(endedCall(), ConversationState.LOADED, aiDetail));

        mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("&lt;script&gt;alert(1)&lt;/script&gt;")))
            .andExpect(content().string(not(containsString("<script>alert(1)"))));
    }

    @Test
    void detail_unknownSession_shows404ErrorScreen() throws Exception {
        given(adminCallDetailService.getDetail(SESSION_ID))
            .willThrow(new CustomException(ErrorCode.CALL_SESSION_NOT_FOUND));

        mockMvc.perform(get(PATH + "/{id}", SESSION_ID).with(asAdmin()))
            .andExpect(status().isNotFound())
            .andExpect(view().name("admin/error"));
    }

    @Test
    void withoutSession_redirectsToLogin() throws Exception {
        mockMvc.perform(get(PATH))
            .andExpect(status().is3xxRedirection())
            .andExpect(header().string("Location", containsString("/admin/login")));
        mockMvc.perform(get(PATH + "/{id}", SESSION_ID))
            .andExpect(status().is3xxRedirection())
            .andExpect(header().string("Location", containsString("/admin/login")));
    }

    private CallHistoryPageResponse pageOf(List<CallHistoryItemResponse> items, int page, int size, long total) {
        return new CallHistoryPageResponse(items, page, size, total);
    }

    private CallHistoryItemResponse endedCall() {
        return new CallHistoryItemResponse(SESSION_ID, MEMBER_ID, "통화자", "foo@example.com",
            Instant.parse("2026-10-20T03:00:00Z"), 125, CallStatus.ENDED, EndReason.USER_HANGUP, "gpt-test");
    }

    private CallHistoryItemResponse pendingCall() {
        return new CallHistoryItemResponse(null, MEMBER_ID, "통화자", "foo@example.com",
            Instant.parse("2026-10-20T04:00:00Z"), 0, CallStatus.PENDING, null, null);
    }

}
