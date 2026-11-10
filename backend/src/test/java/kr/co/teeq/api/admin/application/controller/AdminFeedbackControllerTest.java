package kr.co.teeq.api.admin.application.controller;

import static kr.co.teeq.api.admin.support.AdminTestAuthentication.asAdmin;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.matchesPattern;
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

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.admin.infrastructure.config.AdminSecurityConfig;
import kr.co.teeq.api.admin.support.AdminSliceTestConfig;
import kr.co.teeq.api.common.application.exception.GlobalExceptionHandler;
import kr.co.teeq.api.feedback.application.dto.request.FeedbackSearchRequest;
import kr.co.teeq.api.feedback.application.dto.response.FeedbackListItemResponse;
import kr.co.teeq.api.feedback.application.dto.response.FeedbackPageResponse;
import kr.co.teeq.api.feedback.application.service.FeedbackQueryService;
import kr.co.teeq.api.feedback.core.constant.RevisitIntention;
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

@WebMvcTest(controllers = AdminFeedbackController.class)
@ActiveProfiles("test")
@Import({
    AdminSecurityConfig.class,
    AdminSliceTestConfig.class,
    GlobalExceptionHandler.class,
    AdminExceptionHandler.class,
    AdminFeedbackController.class
})
class AdminFeedbackControllerTest {

    private static final String PATH = "/admin/feedbacks";
    private static final String SESSION_ID = "session-0001";
    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AdminRepository adminRepository;

    @MockitoBean
    private FeedbackQueryService feedbackQueryService;

    @Test
    void feedbacks_rendersRowLinkingToCallDetail() throws Exception {
        given(feedbackQueryService.search(any(), any()))
            .willReturn(new FeedbackPageResponse(List.of(item(SESSION_ID, true)), 0, 20, 1));

        mockMvc.perform(get(PATH).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(view().name("admin/feedbacks"))
            .andExpect(content().string(containsString("href=\"/admin/calls/" + SESSION_ID + "\"")))
            // 한국 시간 2026-10-20 12:00 시작
            .andExpect(content().string(containsString("2026-10-20 12:00:00")))
            .andExpect(content().string(containsString("href=\"/admin/members/" + MEMBER_ID + "\"")))
            .andExpect(content().string(containsString("테스터")))
            .andExpect(content().string(containsString("foo@example.com")))
            .andExpect(content().string(containsString("4점")))
            .andExpect(content().string(containsString("다시 이용하고 싶음")))
            .andExpect(content().string(not(containsString(">YES<"))))
            .andExpect(content().string(containsString("제출함")))
            // 최상위 목록이라 위치 경로를 두지 않는다
            .andExpect(content().string(not(containsString("class=\"breadcrumb\""))))
            // 사이드바의 피드백 메뉴가 활성이다
            .andExpect(content().string(matchesPattern(
                "(?s).*<a href=\"/admin/feedbacks\" aria-current=\"page\" class=\"active\">피드백</a>.*")));

        ArgumentCaptor<FeedbackSearchRequest> request = ArgumentCaptor.forClass(FeedbackSearchRequest.class);
        ArgumentCaptor<Pageable> pageable = ArgumentCaptor.forClass(Pageable.class);
        verify(feedbackQueryService).search(request.capture(), pageable.capture());
        assertThat(request.getValue()).isEqualTo(new FeedbackSearchRequest(null, null, null, null, false));
        assertThat(pageable.getValue()).isEqualTo(PageRequest.of(0, 20));
    }

    @Test
    void feedbacks_rowWithoutCallSessionId_rendersPlainTextWithoutDetailLink() throws Exception {
        given(feedbackQueryService.search(any(), any()))
            .willReturn(new FeedbackPageResponse(List.of(item(null, false)), 0, 20, 1));

        mockMvc.perform(get(PATH).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("2026-10-20 12:00:00")))
            .andExpect(content().string(not(containsString("/admin/calls/"))));
    }

    @Test
    void feedbacks_empty_rendersEmptyMessage() throws Exception {
        given(feedbackQueryService.search(any(), any())).willReturn(new FeedbackPageResponse(List.of(), 0, 20, 0));

        mockMvc.perform(get(PATH).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("피드백이 없습니다.")));
    }

    @Test
    void feedbacks_withFilters_keepsFormValuesAndPassesRequest() throws Exception {
        given(feedbackQueryService.search(any(), any())).willReturn(new FeedbackPageResponse(List.of(), 0, 20, 0));

        mockMvc.perform(get(PATH).with(asAdmin())
                .param("from", "2026-10-01").param("to", "2026-10-31")
                .param("rating", "4").param("detailedOnly", "true"))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("value=\"2026-10-01\"")))
            .andExpect(content().string(containsString("value=\"2026-10-31\"")))
            .andExpect(content().string(matchesPattern(
                "(?s).*<option value=\"4\" selected=\"selected\">4점</option>.*")))
            .andExpect(content().string(matchesPattern(
                "(?s).*name=\"detailedOnly\" value=\"true\" checked=\"checked\".*")))
            .andExpect(content().string(containsString("action=\"/admin/feedbacks\"")));

        ArgumentCaptor<FeedbackSearchRequest> request = ArgumentCaptor.forClass(FeedbackSearchRequest.class);
        verify(feedbackQueryService).search(request.capture(), any());
        assertThat(request.getValue()).isEqualTo(new FeedbackSearchRequest(
            null, LocalDate.of(2026, 10, 1), LocalDate.of(2026, 10, 31), 4, true));
    }

    @Test
    void feedbacks_middlePage_paginationLinksCarryOnlyFiltersWithValues() throws Exception {
        given(feedbackQueryService.search(any(), any()))
            .willReturn(new FeedbackPageResponse(List.of(item(SESSION_ID, true)), 1, 20, 41));

        mockMvc.perform(get(PATH).with(asAdmin())
                .param("rating", "4").param("detailedOnly", "true").param("page", "1"))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("2 / 3")))
            .andExpect(content().string(containsString(
                "href=\"/admin/feedbacks?rating=4&amp;detailedOnly=true&amp;page=0\"")))
            .andExpect(content().string(containsString(
                "href=\"/admin/feedbacks?rating=4&amp;detailedOnly=true&amp;page=2\"")));

        ArgumentCaptor<Pageable> pageable = ArgumentCaptor.forClass(Pageable.class);
        verify(feedbackQueryService).search(any(), pageable.capture());
        assertThat(pageable.getValue()).isEqualTo(PageRequest.of(1, 20));
    }

    @Test
    void feedbacks_malformedParameters_show400ErrorScreenWithoutCallingService() throws Exception {
        mockMvc.perform(get(PATH).with(asAdmin()).param("rating", "abc"))
            .andExpect(status().isBadRequest())
            .andExpect(view().name("admin/error"));
        mockMvc.perform(get(PATH).with(asAdmin()).param("from", "2026-13-45"))
            .andExpect(status().isBadRequest())
            .andExpect(view().name("admin/error"));

        verify(feedbackQueryService, never()).search(any(), any());
    }

    @Test
    void withoutSession_redirectsToLogin() throws Exception {
        mockMvc.perform(get(PATH))
            .andExpect(status().is3xxRedirection())
            .andExpect(header().string("Location", containsString("/admin/login")));
    }

    private FeedbackListItemResponse item(String callSessionId, boolean detailedSubmitted) {
        return new FeedbackListItemResponse(callSessionId, MEMBER_ID, "테스터", "foo@example.com",
            Instant.parse("2026-10-20T03:00:00Z"), 4, RevisitIntention.YES, detailedSubmitted);
    }

}
