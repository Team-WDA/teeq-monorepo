package kr.co.teeq.api.admin.application.controller;

import static kr.co.teeq.api.admin.support.AdminTestAuthentication.asAdmin;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.stringContainsInOrder;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.view;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.admin.infrastructure.config.AdminSecurityConfig;
import kr.co.teeq.api.admin.support.AdminSliceTestConfig;
import kr.co.teeq.api.call.application.dto.response.CallUsageResponse;
import kr.co.teeq.api.call.application.service.CallUsageService;
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

@WebMvcTest(controllers = AdminCallUsageController.class)
@ActiveProfiles("test")
@Import({
    AdminSecurityConfig.class,
    AdminSliceTestConfig.class,
    GlobalExceptionHandler.class,
    AdminExceptionHandler.class,
    AdminCallUsageController.class
})
class AdminCallUsageControllerTest {

    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AdminRepository adminRepository;

    @MockitoBean
    private CallUsageService callUsageService;

    @Test
    void getUsages_withFilters_callsServiceAndRendersRows() throws Exception {
        LocalDate from = LocalDate.of(2026, 10, 1);
        LocalDate to = LocalDate.of(2026, 10, 3);
        given(callUsageService.getUsages(CallUsageUnit.DAY, from, to, null)).willReturn(List.of(
            new CallUsageResponse(LocalDate.of(2026, 10, 1), 1_200, 3),
            new CallUsageResponse(LocalDate.of(2026, 10, 2), 0, 0),
            new CallUsageResponse(LocalDate.of(2026, 10, 3), 3_400, 5)));

        mockMvc.perform(get("/admin/call-usages")
                .with(asAdmin())
                .param("unit", "DAY")
                .param("from", "2026-10-01")
                .param("to", "2026-10-03"))
            .andExpect(status().isOk())
            .andExpect(view().name("admin/call-usages"))
            .andExpect(content().string(containsString("2026-10-01")))
            .andExpect(content().string(containsString("2026-10-02")))
            .andExpect(content().string(containsString("2026-10-03")))
            .andExpect(content().string(containsString("1,200")))
            .andExpect(content().string(containsString("3,400")))
            // 합계 행: 4,600초, 8회
            .andExpect(content().string(containsString("합계")))
            .andExpect(content().string(containsString("4,600")))
            // 필터가 폼에 남는다
            .andExpect(content().string(containsString("value=\"2026-10-01\"")))
            .andExpect(content().string(containsString("value=\"2026-10-03\"")))
            // 회원 필터가 없으면 보너스 링크가 없다
            .andExpect(content().string(not(containsString("/admin/members/"))));

        verify(callUsageService).getUsages(CallUsageUnit.DAY, from, to, null);
    }

    @Test
    void getUsages_withoutParams_usesDefaultLastSevenDays() throws Exception {
        // 고정 Clock 2026-10-20T03:00Z = 한국 시간 2026-10-20 12:00
        LocalDate from = LocalDate.of(2026, 10, 14);
        LocalDate to = LocalDate.of(2026, 10, 20);
        given(callUsageService.getUsages(CallUsageUnit.DAY, from, to, null)).willReturn(List.of(
            new CallUsageResponse(to, 60, 1)));

        mockMvc.perform(get("/admin/call-usages").with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("value=\"2026-10-14\"")))
            .andExpect(content().string(containsString("value=\"2026-10-20\"")));

        verify(callUsageService).getUsages(CallUsageUnit.DAY, from, to, null);
    }

    @Test
    void getUsages_withMonthUnit_passesUnitToService() throws Exception {
        LocalDate from = LocalDate.of(2026, 8, 1);
        LocalDate to = LocalDate.of(2026, 10, 31);
        given(callUsageService.getUsages(CallUsageUnit.MONTH, from, to, null)).willReturn(List.of(
            new CallUsageResponse(LocalDate.of(2026, 8, 1), 10, 1)));

        mockMvc.perform(get("/admin/call-usages")
                .with(asAdmin())
                .param("unit", "MONTH")
                .param("from", "2026-08-01")
                .param("to", "2026-10-31"))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("2026-08-01")));

        verify(callUsageService).getUsages(CallUsageUnit.MONTH, from, to, null);
    }

    @Test
    void getUsages_withInvalidRange_showsErrorMessage() throws Exception {
        given(callUsageService.getUsages(CallUsageUnit.DAY, LocalDate.of(2026, 10, 5), LocalDate.of(2026, 10, 1), null))
            .willThrow(new CustomException(ErrorCode.INVALID_REQUEST));

        mockMvc.perform(get("/admin/call-usages")
                .with(asAdmin())
                .param("from", "2026-10-05")
                .param("to", "2026-10-01"))
            .andExpect(status().isBadRequest())
            .andExpect(view().name("admin/error"))
            .andExpect(content().string(containsString(ErrorCode.INVALID_REQUEST.message())));
    }

    @Test
    void getUsages_withMalformedMemberId_showsErrorMessage() throws Exception {
        mockMvc.perform(get("/admin/call-usages")
                .with(asAdmin())
                .param("memberId", "abc"))
            .andExpect(status().isBadRequest())
            .andExpect(view().name("admin/error"))
            .andExpect(content().string(containsString(ErrorCode.INVALID_REQUEST.message())));

        verify(callUsageService, never()).getUsages(any(), any(), any(), any());
    }

    @Test
    void getUsages_withMalformedUnitOrDate_showsErrorMessage() throws Exception {
        mockMvc.perform(get("/admin/call-usages").with(asAdmin()).param("unit", "WEEK"))
            .andExpect(status().isBadRequest())
            .andExpect(view().name("admin/error"));

        mockMvc.perform(get("/admin/call-usages").with(asAdmin()).param("from", "2026-13-45"))
            .andExpect(status().isBadRequest())
            .andExpect(view().name("admin/error"));
    }

    @Test
    void getUsages_withUnknownMember_showsErrorMessage() throws Exception {
        given(callUsageService.getUsages(CallUsageUnit.DAY, LocalDate.of(2026, 10, 14), LocalDate.of(2026, 10, 20),
            MEMBER_ID)).willThrow(new CustomException(ErrorCode.MEMBER_NOT_FOUND));

        mockMvc.perform(get("/admin/call-usages")
                .with(asAdmin())
                .param("memberId", MEMBER_ID.toString()))
            .andExpect(status().isNotFound())
            .andExpect(view().name("admin/error"))
            .andExpect(content().string(containsString(ErrorCode.MEMBER_NOT_FOUND.message())));
    }

    @Test
    void memberIdFilter_linksToMemberDetailScreen() throws Exception {
        given(callUsageService.getUsages(CallUsageUnit.DAY, LocalDate.of(2026, 10, 14), LocalDate.of(2026, 10, 20),
            MEMBER_ID)).willReturn(List.of(new CallUsageResponse(LocalDate.of(2026, 10, 20), 60, 1)));

        mockMvc.perform(get("/admin/call-usages")
                .with(asAdmin())
                .param("memberId", MEMBER_ID.toString()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("href=\"/admin/members/" + MEMBER_ID + "\"")))
            .andExpect(content().string(containsString("value=\"" + MEMBER_ID + "\"")));
    }

    @Test
    void getUsages_withEmptyResult_showsEmptyMessageAndZeroTotals() throws Exception {
        given(callUsageService.getUsages(CallUsageUnit.DAY, LocalDate.of(2026, 10, 14), LocalDate.of(2026, 10, 20),
            null)).willReturn(List.of());

        mockMvc.perform(get("/admin/call-usages").with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("조회된 기간이 없습니다")))
            // 합계 행의 사용 시간과 통화 횟수가 0으로 표시된다
            .andExpect(content().string(stringContainsInOrder(
                "call-usage-total-row", "<th class=\"numeric-cell\">0</th>", "<th class=\"numeric-cell\">0</th>")));
    }

    @Test
    void getUsages_withBlankFormFields_treatsThemAsDefaults() throws Exception {
        // 빈 폼을 제출하면 브라우저가 memberId, from, to를 빈 문자열로 보낸다
        LocalDate from = LocalDate.of(2026, 10, 14);
        LocalDate to = LocalDate.of(2026, 10, 20);
        given(callUsageService.getUsages(CallUsageUnit.DAY, from, to, null)).willReturn(List.of(
            new CallUsageResponse(to, 60, 1)));

        mockMvc.perform(get("/admin/call-usages")
                .with(asAdmin())
                .param("unit", "DAY")
                .param("memberId", "")
                .param("from", "")
                .param("to", ""))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("value=\"2026-10-14\"")))
            .andExpect(content().string(containsString("value=\"2026-10-20\"")));

        verify(callUsageService).getUsages(CallUsageUnit.DAY, from, to, null);
    }

    @Test
    void getUsages_withoutSession_redirectsToLogin() throws Exception {
        mockMvc.perform(get("/admin/call-usages"))
            .andExpect(status().is3xxRedirection())
            .andExpect(header().string("Location", containsString("/admin/login")));
    }

}
