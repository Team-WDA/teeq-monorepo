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

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import kr.co.teeq.api.admin.application.dto.response.AdminAiMetricsResponse;
import kr.co.teeq.api.admin.application.dto.response.AdminAiMetricsRow;
import kr.co.teeq.api.admin.application.dto.response.AdminAiSummaryResponse;
import kr.co.teeq.api.admin.application.service.AdminAiMetricsService;
import kr.co.teeq.api.admin.infrastructure.config.AdminSecurityConfig;
import kr.co.teeq.api.admin.support.AdminSliceTestConfig;
import kr.co.teeq.api.call.core.constant.CallUsageUnit;
import kr.co.teeq.api.common.application.exception.GlobalExceptionHandler;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.repository.AdminRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(controllers = AdminAiServerController.class)
@ActiveProfiles("test")
@Import({
    AdminSecurityConfig.class,
    AdminSliceTestConfig.class,
    GlobalExceptionHandler.class,
    AdminExceptionHandler.class,
    AdminAiServerController.class
})
class AdminAiServerControllerTest {

    private static final String PATH = "/admin/ai-server";
    private static final String SUMMARY_PATH = "/admin/ai-server/summary";
    private static final AdminAiMetricsRow TOTAL_ROW = new AdminAiMetricsRow(null, 128, 121, 2304, 790, 1910,
        new BigDecimal("5.37"), 9);

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AdminRepository adminRepository;

    @MockitoBean
    private AdminAiMetricsService adminAiMetricsService;

    @Test
    void 기본_조회는_일별_전체_기간으로_서비스를_호출한다() throws Exception {
        given(adminAiMetricsService.getMetrics(CallUsageUnit.DAY, null, null))
            .willReturn(metrics(CallUsageUnit.DAY, null, null, sampleRows()));

        mockMvc.perform(get(PATH).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(view().name("admin/ai-server"))
            .andExpect(content().string(containsString("AI 품질·비용")))
            .andExpect(content().string(containsString("일별 p95 지연")))
            .andExpect(content().string(not(containsString("aria-label=\"위치 경로\""))));

        verify(adminAiMetricsService).getMetrics(CallUsageUnit.DAY, null, null);
    }

    @Test
    void 지정한_기간과_단위를_서비스에_넘기고_폼에_유지한다() throws Exception {
        LocalDate from = LocalDate.parse("2026-10-01");
        LocalDate to = LocalDate.parse("2026-11-10");
        given(adminAiMetricsService.getMetrics(CallUsageUnit.MONTH, from, to))
            .willReturn(metrics(CallUsageUnit.MONTH, from, to, List.of(
                new AdminAiMetricsRow(LocalDate.parse("2026-10-01"), 5, 5, 120, 780, 1520, new BigDecimal("0.24"), 1),
                new AdminAiMetricsRow(LocalDate.parse("2026-11-01"), 7, 7, 160, 810, 1740, new BigDecimal("0.31"),
                    0))));

        mockMvc.perform(get(PATH).with(asAdmin())
                .param("unit", "MONTH").param("from", "2026-10-01").param("to", "2026-11-10"))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("value=\"2026-10-01\"")))
            .andExpect(content().string(containsString("value=\"2026-11-10\"")))
            .andExpect(content().string(containsString("<option value=\"MONTH\" selected")))
            .andExpect(content().string(containsString("월별 p95 지연")))
            // 월 단위 기간은 yyyy-MM으로 보인다
            .andExpect(content().string(containsString(">2026-11</td>")))
            .andExpect(content().string(not(containsString(">2026-11-01</td>"))));

        verify(adminAiMetricsService).getMetrics(CallUsageUnit.MONTH, from, to);
    }

    @Test
    void 요약_타일과_표에_값을_보여_준다() throws Exception {
        given(adminAiMetricsService.getMetrics(CallUsageUnit.DAY, null, null))
            .willReturn(metrics(CallUsageUnit.DAY, null, null, sampleRows()));

        mockMvc.perform(get(PATH).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("121건")))
            .andExpect(content().string(containsString("전체 128건 중")))
            .andExpect(content().string(containsString("턴 2,304개")))
            .andExpect(content().string(containsString("790ms")))
            .andExpect(content().string(containsString("1,910ms")))
            .andExpect(content().string(containsString("$5.37")))
            .andExpect(content().string(containsString("공개 단가 기준 대략값")))
            .andExpect(content().string(containsString("2026-11-02")))
            .andExpect(content().string(containsString("1,740ms")))
            // 행: 기간, 통화 수, 집계 통화, 턴 수, p50, p95, 비용, 비정상 종료
            .andExpect(content().string(matchesPattern("(?s).*>2026-11-01</td>"
                + numericCells("3", "3", "71", "780ms", "1,520ms", "\\$0.24", "1") + ".*")))
            // 비용은 소수 둘째 자리까지 보인다
            .andExpect(content().string(matchesPattern("(?s).*>2026-11-03</td>"
                + numericCells("1", "1", "20", "700ms", "900ms", "\\$0.02", "0") + ".*")))
            .andExpect(content().string(containsString("call-usage-total-row")))
            .andExpect(content().string(matchesPattern("(?s).*<th>합계</th>"
                + numericHeaderCells("128", "121", "2,304", "790ms", "1,910ms", "\\$5.37", "9") + ".*")));
    }

    @Test
    void 값이_없으면_측정_안_됨을_보인다() throws Exception {
        AdminAiMetricsRow emptyTotal = new AdminAiMetricsRow(null, 2, 0, 0, null, null, BigDecimal.ZERO, 2);
        given(adminAiMetricsService.getMetrics(CallUsageUnit.DAY, null, null)).willReturn(
            new AdminAiMetricsResponse(CallUsageUnit.DAY, null, null, false,
                List.of(new AdminAiMetricsRow(LocalDate.parse("2026-10-23"), 2, 0, 0, null, null, BigDecimal.ZERO,
                    2)), emptyTotal));

        mockMvc.perform(get(PATH).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(matchesPattern("(?s).*>2026-10-23</td>"
                + numericCells("2", "0", "0", "측정 안 됨", "측정 안 됨", "\\$0.00", "2") + ".*")))
            .andExpect(content().string(matchesPattern("(?s).*<th>합계</th>"
                + numericHeaderCells("2", "0", "0", "측정 안 됨", "측정 안 됨", "\\$0.00", "2") + ".*")))
            .andExpect(content().string(not(containsString("0ms"))));
    }

    @Test
    void p95가_모두_null이어도_막대_차트가_나누기_오류_없이_렌더링된다() throws Exception {
        List<AdminAiMetricsRow> rows = List.of(
            AdminAiMetricsRow.empty(LocalDate.parse("2026-11-01")),
            AdminAiMetricsRow.empty(LocalDate.parse("2026-11-02")),
            AdminAiMetricsRow.empty(LocalDate.parse("2026-11-03")));
        given(adminAiMetricsService.getMetrics(CallUsageUnit.DAY, null, null))
            .willReturn(metrics(CallUsageUnit.DAY, null, null, rows));

        String body = mockMvc.perform(get(PATH).with(asAdmin()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertThat(body.split("usage-chart-bar usage-chart-bar-empty", -1)).hasSize(rows.size() + 1);
        assertThat(body.split("--bar-height: 0%", -1)).hasSize(rows.size() + 1);
        assertThat(body).contains("측정 안 됨");
    }

    @Test
    void 막대_높이는_가장_큰_p95를_100으로_둔다() throws Exception {
        given(adminAiMetricsService.getMetrics(CallUsageUnit.DAY, null, null))
            .willReturn(metrics(CallUsageUnit.DAY, null, null, sampleRows()));

        mockMvc.perform(get(PATH).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("--bar-height: 100%")))
            .andExpect(content().string(containsString("--bar-height: 87%")))
            .andExpect(content().string(containsString("ai-metrics-chart-scroll")))
            .andExpect(content().string(not(containsString("usage-chart-bar-empty"))));
    }

    @Test
    void AI_서버가_불가하면_안내와_다시_시도를_보인다() throws Exception {
        LocalDate from = LocalDate.parse("2026-11-01");
        given(adminAiMetricsService.getMetrics(CallUsageUnit.DAY, from, null)).willReturn(
            new AdminAiMetricsResponse(CallUsageUnit.DAY, from, null, true, List.of(),
                AdminAiMetricsRow.empty(null)));

        mockMvc.perform(get(PATH).with(asAdmin()).param("from", "2026-11-01"))
            .andExpect(status().isOk())
            .andExpect(view().name("admin/ai-server"))
            .andExpect(content().string(containsString("AI 서버 데이터를 불러오지 못했습니다.")))
            .andExpect(content().string(containsString("다시 시도")))
            .andExpect(content().string(containsString(
                "href=\"/admin/ai-server?unit=DAY&amp;from=2026-11-01&amp;to=\"")))
            // 필터는 남는다
            .andExpect(content().string(containsString("value=\"2026-11-01\"")))
            .andExpect(content().string(not(containsString("<table"))))
            .andExpect(content().string(not(containsString("usage-chart"))))
            .andExpect(content().string(not(containsString("추정 비용 합계"))));
    }

    @Test
    void 조회된_기간이_없으면_빈_행을_보인다() throws Exception {
        given(adminAiMetricsService.getMetrics(CallUsageUnit.DAY, null, null))
            .willReturn(metrics(CallUsageUnit.DAY, null, null, List.of()));

        mockMvc.perform(get(PATH).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("조회된 기간이 없습니다.")))
            .andExpect(content().string(not(containsString("usage-chart"))));
    }

    @Test
    void 시작일이_종료일보다_늦으면_오류_화면이다() throws Exception {
        given(adminAiMetricsService.getMetrics(any(), any(), any()))
            .willThrow(new CustomException(ErrorCode.INVALID_REQUEST));

        mockMvc.perform(get(PATH).with(asAdmin()).param("from", "2026-11-03").param("to", "2026-11-02"))
            .andExpect(status().isBadRequest())
            .andExpect(view().name("admin/error"));
    }

    @Test
    void 형식이_틀린_단위나_날짜는_400이다() throws Exception {
        mockMvc.perform(get(PATH).with(asAdmin()).param("unit", "WEEK"))
            .andExpect(status().isBadRequest()).andExpect(view().name("admin/error"));
        mockMvc.perform(get(PATH).with(asAdmin()).param("from", "2026-13-45"))
            .andExpect(status().isBadRequest()).andExpect(view().name("admin/error"));
        mockMvc.perform(get(PATH).with(asAdmin()).param("to", "abc"))
            .andExpect(status().isBadRequest()).andExpect(view().name("admin/error"));

        verify(adminAiMetricsService, never()).getMetrics(any(), any(), any());
    }

    @Test
    void ADMIN도_조회할_수_있다() throws Exception {
        given(adminAiMetricsService.getMetrics(CallUsageUnit.DAY, null, null))
            .willReturn(metrics(CallUsageUnit.DAY, null, null, List.of()));

        mockMvc.perform(get(PATH).with(asAdmin()))
            .andExpect(status().isOk())
            // 사이드바의 AI 서버 메뉴가 강조된다
            .andExpect(content().string(matchesPattern(
                "(?s).*<a href=\"/admin/ai-server\" aria-current=\"page\" class=\"active\">AI 서버</a>.*")));
    }

    @Test
    void 비로그인은_로그인으로_이동한다() throws Exception {
        mockMvc.perform(get(PATH))
            .andExpect(status().isFound())
            .andExpect(header().string("Location", containsString("/admin/login")));

        verify(adminAiMetricsService, never()).getMetrics(any(), any(), any());
    }

    @Test
    void summary_rendersTodayAndAllTimeColumns() throws Exception {
        AdminAiMetricsRow today = new AdminAiMetricsRow(LocalDate.parse("2026-10-20"), 5, 5, 120, 790, 1740,
            new BigDecimal("0.31"), 1);
        given(adminAiMetricsService.getSummary()).willReturn(new AdminAiSummaryResponse(false, today, TOTAL_ROW));

        mockMvc.perform(get(SUMMARY_PATH).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(view().name("admin/fragments/ai-server-summary :: ai-server-summary"))
            .andExpect(content().string(containsString("id=\"dashboard-ai-server-status\"")))
            .andExpect(content().string(containsString("AI 서버 상태")))
            .andExpect(content().string(containsString("오늘")))
            .andExpect(content().string(containsString("전체 누적")))
            .andExpect(content().string(containsString("790ms")))
            .andExpect(content().string(containsString("p50 · p95 1,740ms")))
            .andExpect(content().string(containsString("p50 · p95 1,910ms")))
            .andExpect(content().string(containsString("$0.31")))
            .andExpect(content().string(containsString("$5.37")))
            .andExpect(content().string(containsString("비정상 종료 1건")))
            .andExpect(content().string(containsString("비정상 종료 9건")))
            .andExpect(content().string(containsString("통화 121건 · 턴 2,304개 기준 (대략값)")))
            .andExpect(content().string(containsString("href=\"/admin/ai-server\"")))
            .andExpect(content().string(containsString("AI 품질·비용 보기")))
            // 교체된 조각은 다시 불러오지 않는다
            .andExpect(content().string(not(containsString("hx-trigger"))));
    }

    @Test
    void summary_showsNotMeasuredForNullLatency() throws Exception {
        given(adminAiMetricsService.getSummary()).willReturn(new AdminAiSummaryResponse(false,
            AdminAiMetricsRow.empty(LocalDate.parse("2026-10-20")), TOTAL_ROW));

        String body = mockMvc.perform(get(SUMMARY_PATH).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("측정 안 됨")))
            .andExpect(content().string(containsString("$0.00")))
            .andExpect(content().string(containsString("비정상 종료 0건")))
            .andReturn().getResponse().getContentAsString();

        // 오늘 열의 p50(큰 숫자)과 p95 두 곳
        assertThat(body.split("측정 안 됨", -1)).hasSize(3);
    }

    @Test
    void summary_unavailableShowsRetryButtonWithoutErrorNotice() throws Exception {
        given(adminAiMetricsService.getSummary()).willReturn(new AdminAiSummaryResponse(true,
            AdminAiMetricsRow.empty(LocalDate.parse("2026-10-20")), AdminAiMetricsRow.empty(null)));

        mockMvc.perform(get(SUMMARY_PATH).with(asAdmin()).header("HX-Request", "true"))
            .andExpect(status().isOk())
            .andExpect(header().doesNotExist("HX-Retarget"))
            .andExpect(content().string(containsString("id=\"dashboard-ai-server-status\"")))
            .andExpect(content().string(containsString("AI 서버 데이터를 불러오지 못했습니다.")))
            .andExpect(content().string(containsString("다시 시도")))
            .andExpect(content().string(containsString("hx-get=\"/admin/ai-server/summary\"")))
            .andExpect(content().string(containsString("hx-target=\"#dashboard-ai-server-status\"")))
            .andExpect(content().string(containsString("hx-swap=\"outerHTML\"")))
            .andExpect(content().string(not(containsString("전체 누적"))));
    }

    @Test
    void summary_isFragmentOnly() throws Exception {
        given(adminAiMetricsService.getSummary()).willReturn(new AdminAiSummaryResponse(false,
            AdminAiMetricsRow.empty(LocalDate.parse("2026-10-20")), TOTAL_ROW));

        mockMvc.perform(get(SUMMARY_PATH).with(asAdmin()).header("HX-Request", "true"))
            .andExpect(status().isOk())
            .andExpect(content().string(not(containsString("<html"))))
            .andExpect(content().string(not(containsString("class=\"sidebar\""))))
            .andExpect(content().string(not(containsString("htmx-error-notice"))));
    }

    @Test
    void summary_withoutSession_redirectsToLogin() throws Exception {
        mockMvc.perform(get(SUMMARY_PATH))
            .andExpect(status().isFound())
            .andExpect(header().string("Location", containsString("/admin/login")));

        verify(adminAiMetricsService, never()).getSummary();
    }

    private static List<AdminAiMetricsRow> sampleRows() {
        return List.of(
            new AdminAiMetricsRow(LocalDate.parse("2026-11-01"), 3, 3, 71, 780, 1520, new BigDecimal("0.24"), 1),
            new AdminAiMetricsRow(LocalDate.parse("2026-11-02"), 4, 4, 96, 810, 1740, new BigDecimal("0.31"), 0),
            new AdminAiMetricsRow(LocalDate.parse("2026-11-03"), 1, 1, 20, 700, 900, new BigDecimal("0.0223"), 0));
    }

    private static AdminAiMetricsResponse metrics(CallUsageUnit unit, LocalDate from, LocalDate to,
        List<AdminAiMetricsRow> rows) {
        return new AdminAiMetricsResponse(unit, from, to, false, rows, TOTAL_ROW);
    }

    private static String numericCells(String... cellTexts) {
        StringBuilder pattern = new StringBuilder();
        for (String cellText : cellTexts) {
            pattern.append("\\s*<td class=\"numeric-cell\">").append(cellText).append("</td>");
        }
        return pattern.toString();
    }

    private static String numericHeaderCells(String... cellTexts) {
        StringBuilder pattern = new StringBuilder();
        for (String cellText : cellTexts) {
            pattern.append("\\s*<th class=\"numeric-cell\">").append(cellText).append("</th>");
        }
        return pattern.toString();
    }

}
