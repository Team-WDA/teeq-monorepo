package kr.co.teeq.api.admin.application.controller;

import static kr.co.teeq.api.admin.support.AdminTestAuthentication.asAdmin;
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

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AdminRepository adminRepository;

    @MockitoBean
    private AdminDashboardService adminDashboardService;

    @Test
    void home_rendersKpisAndMenu() throws Exception {
        given(adminDashboardService.getDashboard()).willReturn(dashboard(568_000, 900_000,
            List.of(new RecentMember("m***@gmail.com", AdminSliceTestConfig.NOW)),
            List.of(new RecentFeedback("필수", 4, AdminSliceTestConfig.NOW, null),
                new RecentFeedback("상세", null, AdminSliceTestConfig.NOW, "목소리가 좋아요")),
            List.of(new RecentBonus(LocalDate.of(2026, 10, 20), 600, "이벤트", AdminSliceTestConfig.NOW))));

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
            .andExpect(content().string(containsString("href=\"/admin/call-usages\"")))
            .andExpect(content().string(containsString("href=\"/admin/call-bonuses\"")))
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
