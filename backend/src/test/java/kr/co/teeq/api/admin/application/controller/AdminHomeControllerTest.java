package kr.co.teeq.api.admin.application.controller;

import static kr.co.teeq.api.admin.support.AdminTestAuthentication.asAdmin;
import static kr.co.teeq.api.admin.support.AdminTestAuthentication.asSuperAdmin;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.view;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.admin.application.dto.response.AdminDashboardResponse;
import kr.co.teeq.api.admin.application.dto.response.AdminDashboardResponse.RecentBonus;
import kr.co.teeq.api.admin.application.dto.response.AdminDashboardResponse.RecentFeedback;
import kr.co.teeq.api.admin.application.dto.response.AdminDashboardResponse.RecentMember;
import kr.co.teeq.api.admin.application.service.AdminDashboardService;
import kr.co.teeq.api.admin.infrastructure.config.AdminSecurityConfig;
import kr.co.teeq.api.admin.support.AdminSliceTestConfig;
import kr.co.teeq.api.call.application.dto.response.CallUsageResponse;
import kr.co.teeq.api.common.application.exception.GlobalExceptionHandler;
import kr.co.teeq.api.member.core.repository.AdminRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(controllers = AdminHomeController.class)
@ActiveProfiles("test")
@Import({
    AdminSecurityConfig.class,
    AdminSliceTestConfig.class,
    GlobalExceptionHandler.class,
    AdminExceptionHandler.class,
    AdminHomeController.class
})
class AdminHomeControllerTest {

    private static final UUID MEMBER_ID = UUID.fromString("0192f0aa-0000-7000-8000-000000000001");

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AdminRepository adminRepository;

    @MockitoBean
    private AdminDashboardService adminDashboardService;

    @Test
    void home_rendersKpisAndMenu() throws Exception {
        given(adminDashboardService.getDashboard()).willReturn(dashboard(568_000, 900_000,
            List.of(new RecentMember(MEMBER_ID, "m***@gmail.com", AdminSliceTestConfig.NOW)),
            List.of(new RecentFeedback(MEMBER_ID, "필수", 4, AdminSliceTestConfig.NOW, null),
                new RecentFeedback(MEMBER_ID, "상세", null, AdminSliceTestConfig.NOW, "목소리가 좋아요")),
            List.of(new RecentBonus(MEMBER_ID, LocalDate.of(2026, 10, 20), 600, "이벤트", AdminSliceTestConfig.NOW))));

        mockMvc.perform(get("/admin").with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(view().name("admin/home"))
            .andExpect(content().string(containsString("주간 재통화 회원")))
            .andExpect(content().string(containsString("128")))
            .andExpect(content().string(containsString("82%")))
            .andExpect(content().string(containsString("63%")))
            .andExpect(content().string(containsString("m***@gmail.com")))
            .andExpect(content().string(containsString("목소리가 좋아요")))
            .andExpect(content().string(containsString("이벤트")))
            // 시각은 KST로 표시한다
            .andExpect(content().string(containsString("2026-10-20 12:00:00")))
            // 이번 달 보너스 KPI는 집계 기준을 밝힌다
            .andExpect(content().string(containsString("취소 제외 · 유효 날짜 기준")))
            .andExpect(content().string(not(containsString("limit-gauge-exceeded"))))
            .andExpect(content().string(containsString("href=\"/admin\"")))
            .andExpect(content().string(containsString("href=\"/admin/settings\"")))
            .andExpect(content().string(containsString("href=\"/admin/members\"")))
            .andExpect(content().string(containsString("href=\"/admin/onboarding-submissions\"")));
    }

    @Test
    void home_withLimitExceeded_showsRealRateAndWarningGauge() throws Exception {
        given(adminDashboardService.getDashboard())
            .willReturn(dashboard(1_000_000, 900_000, List.of(), List.of(), List.of()));

        mockMvc.perform(get("/admin").with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("111%")))
            .andExpect(content().string(containsString("limit-gauge-exceeded")))
            // 막대는 100%에서 멈춘다
            .andExpect(content().string(containsString("--gauge-width: 100%")));
    }

    @Test
    void home_asSuperAdmin_showsAccountMenu() throws Exception {
        given(adminDashboardService.getDashboard())
            .willReturn(dashboard(568_000, 900_000, List.of(), List.of(), List.of()));

        mockMvc.perform(get("/admin").with(asSuperAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("관리자 계정")))
            .andExpect(content().string(containsString("href=\"/admin/accounts\"")));
    }

    @Test
    void home_asAdmin_hidesAccountMenuButShowsPasswordLink() throws Exception {
        given(adminDashboardService.getDashboard())
            .willReturn(dashboard(568_000, 900_000, List.of(), List.of(), List.of()));

        mockMvc.perform(get("/admin").with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(not(containsString("href=\"/admin/accounts\""))))
            .andExpect(content().string(containsString("href=\"/admin/password\"")));
    }

    @Test
    void home_rendersKpiCardLinksAndRecentRowLinks() throws Exception {
        given(adminDashboardService.getDashboard()).willReturn(dashboard(568_000, 900_000,
            List.of(new RecentMember(MEMBER_ID, "m***@gmail.com", AdminSliceTestConfig.NOW)),
            List.of(new RecentFeedback(MEMBER_ID, "필수", 4, AdminSliceTestConfig.NOW, null)),
            List.of(new RecentBonus(MEMBER_ID, LocalDate.of(2026, 10, 20), 600, "이벤트",
                AdminSliceTestConfig.NOW))));

        mockMvc.perform(get("/admin").with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("href=\"/admin/calls\"")))
            .andExpect(content().string(containsString("href=\"/admin/members\"")))
            .andExpect(content().string(containsString("href=\"/admin/onboarding-submissions\"")))
            .andExpect(content().string(containsString("href=\"/admin/feedbacks\"")))
            .andExpect(content().string(containsString("href=\"/admin/members/" + MEMBER_ID + "\"")))
            .andExpect(content().string(containsString("href=\"/admin/members/" + MEMBER_ID + "/call-bonuses\"")))
            .andExpect(content().string(containsString("href=\"/admin/members/" + MEMBER_ID + "/feedbacks\"")));
    }

    @Test
    void home_bonusKpiCardHasNoLink() throws Exception {
        given(adminDashboardService.getDashboard())
            .willReturn(dashboard(568_000, 900_000, List.of(), List.of(), List.of()));

        String body = mockMvc.perform(get("/admin").with(asAdmin()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        // 링크 카드는 5개이고, 이번 달 부여 보너스 카드는 링크로 감싸지 않는다
        assertThat(body.split("class=\"dashboard-kpi-link\"", -1)).hasSize(6);
        // 모든 링크 카드는 <a>가 </a>로 닫힌 뒤 다음 카드가 시작되므로, 보너스 카드 앞의 마지막 <a>는 이미 닫혀 있다
        String beforeBonusCard = body.substring(0, body.indexOf("이번 달 부여 보너스"));
        assertThat(beforeBonusCard.lastIndexOf("<a class=\"dashboard-kpi-link\""))
            .isLessThan(beforeBonusCard.lastIndexOf("</a>"));
    }

    @Test
    void home_rendersConfirmDialogShell() throws Exception {
        given(adminDashboardService.getDashboard())
            .willReturn(dashboard(568_000, 900_000, List.of(), List.of(), List.of()));

        mockMvc.perform(get("/admin").with(asSuperAdmin()))
            .andExpect(status().isOk())
            // 공통 셸이 확인 모달과 data-confirm-* 처리 스크립트를 싣는다
            .andExpect(content().string(containsString("id=\"confirm-dialog\"")))
            .andExpect(content().string(containsString("confirmDialog")))
            // 화면 제목 아래 설명 문구는 보이지 않는다
            .andExpect(content().string(not(containsString("열 때마다 새로 집계합니다"))));
    }

    @Test
    void home_sidebarHasAiServerMenuAfterFeedbackMenu() throws Exception {
        given(adminDashboardService.getDashboard())
            .willReturn(dashboard(568_000, 900_000, List.of(), List.of(), List.of()));

        String body = mockMvc.perform(get("/admin").with(asAdmin()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        String sidebar = body.substring(body.indexOf("<nav class=\"sidebar\""), body.indexOf("</nav>"));
        int feedbackMenuIndex = sidebar.indexOf("href=\"/admin/feedbacks\"");
        int aiServerMenuIndex = sidebar.indexOf("href=\"/admin/ai-server\"");
        int onboardingMenuIndex = sidebar.indexOf("href=\"/admin/onboarding-submissions\"");
        assertThat(feedbackMenuIndex).isNotNegative();
        assertThat(aiServerMenuIndex).isGreaterThan(feedbackMenuIndex).isLessThan(onboardingMenuIndex);
        assertThat(sidebar).contains(">AI 서버</a>");
    }

    @Test
    void 홈에_AI_서버_상태_자리표시가_있다() throws Exception {
        given(adminDashboardService.getDashboard())
            .willReturn(dashboard(568_000, 900_000, List.of(), List.of(), List.of()));

        String body = mockMvc.perform(get("/admin").with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("id=\"dashboard-ai-server-status\"")))
            .andExpect(content().string(containsString("hx-get=\"/admin/ai-server/summary\"")))
            .andExpect(content().string(containsString("hx-trigger=\"load\"")))
            .andExpect(content().string(containsString("hx-swap=\"outerHTML\"")))
            .andExpect(content().string(containsString("AI 서버에서 불러오는 중...")))
            .andReturn().getResponse().getContentAsString();

        // 자리표시는 추이 영역(14일 차트·월 한도) 다음, 최근 목록 영역 앞에 있다
        int placeholderIndex = body.indexOf("id=\"dashboard-ai-server-status\"");
        assertThat(placeholderIndex).isGreaterThan(body.indexOf("이번 달 전체 통화 한도"))
            .isLessThan(body.indexOf("dashboard-recent-grid"));
    }

    @Test
    void home_withoutSession_redirectsToLogin() throws Exception {
        mockMvc.perform(get("/admin"))
            .andExpect(status().isFound())
            .andExpect(header().string("Location", containsString("/admin/login")));
    }

    private AdminDashboardResponse dashboard(long monthUsedSeconds, long monthLimitSeconds,
        List<RecentMember> recentMembers, List<RecentFeedback> recentFeedbacks, List<RecentBonus> recentBonuses) {
        List<CallUsageResponse> dailyUsages = new ArrayList<>();
        for (LocalDate date = LocalDate.of(2026, 10, 7); !date.isAfter(LocalDate.of(2026, 10, 20));
            date = date.plusDays(1)) {
            dailyUsages.add(new CallUsageResponse(date, date.getDayOfMonth() * 100L, 1));
        }
        return new AdminDashboardResponse(128, 1_942, 17, 312, 15_480, 0.82, 38, 8, 12, 6_000,
            dailyUsages, monthUsedSeconds, monthLimitSeconds, (double) monthUsedSeconds / monthLimitSeconds,
            recentMembers, recentFeedbacks, recentBonuses);
    }

}
