package kr.co.teeq.api.admin.application.controller;

import static kr.co.teeq.api.admin.support.AdminTestAuthentication.ADMIN_ID;
import static kr.co.teeq.api.admin.support.AdminTestAuthentication.asAdmin;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.endsWith;
import static org.hamcrest.Matchers.not;
import static org.mockito.ArgumentCaptor.forClass;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
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
import kr.co.teeq.api.call.application.dto.request.CallBonusGrantRequest;
import kr.co.teeq.api.call.application.dto.response.CallBonusResponse;
import kr.co.teeq.api.call.application.service.CallBonusService;
import kr.co.teeq.api.common.application.exception.GlobalExceptionHandler;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.repository.AdminRepository;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(controllers = AdminCallBonusController.class)
@ActiveProfiles("test")
@Import({
    AdminSecurityConfig.class,
    AdminSliceTestConfig.class,
    GlobalExceptionHandler.class,
    AdminExceptionHandler.class,
    AdminCallBonusController.class
})
class AdminCallBonusControllerTest {

    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final UUID ACTIVE_BONUS_ID = UUID.fromString("0199aaaa-0000-7000-8000-000000000001");
    private static final UUID CANCELED_BONUS_ID = UUID.fromString("0199aaaa-0000-7000-8000-000000000002");
    private static final UUID CANCELING_ADMIN_ID = UUID.fromString("0199bbbb-0000-7000-8000-000000000003");

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AdminRepository adminRepository;

    @MockitoBean
    private CallBonusService callBonusService;

    @Test
    void getWithoutMemberId_rendersInputFormOnly() throws Exception {
        mockMvc.perform(get("/admin/call-bonuses").with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(view().name("admin/call-bonuses"))
            .andExpect(content().string(containsString("name=\"memberId\"")))
            // 사이드바의 통화 보너스 메뉴가 강조된다
            .andExpect(content().string(containsString("class=\"active\"")))
            // 목록과 부여 폼은 회원을 정한 뒤에만 보인다
            .andExpect(content().string(not(containsString("/admin/call-bonuses/grant"))));

        verify(callBonusService, never()).getAll(any());
    }

    @Test
    void getWithMemberId_rendersListAndGrantForm() throws Exception {
        given(callBonusService.getAll(MEMBER_ID)).willReturn(List.of(
            activeBonus(),
            canceledBonus()));

        mockMvc.perform(get("/admin/call-bonuses").with(asAdmin()).param("memberId", MEMBER_ID.toString()))
            .andExpect(status().isOk())
            .andExpect(view().name("admin/call-bonuses"))
            .andExpect(content().string(containsString("서비스 장애 보상")))
            .andExpect(content().string(containsString("중복 부여")))
            .andExpect(content().string(containsString("2026-10-21")))
            // 부여 폼: 회원 ID가 숨은 필드로 실리고 CSRF 토큰이 자동 삽입된다
            .andExpect(content().string(containsString("/admin/call-bonuses/grant")))
            .andExpect(content().string(containsString("name=\"_csrf\"")))
            .andExpect(content().string(containsString("name=\"seconds\"")))
            .andExpect(content().string(containsString("name=\"bonusDate\"")))
            .andExpect(content().string(containsString("name=\"reason\"")))
            // 취소 버튼은 취소되지 않은 항목에만 있다
            .andExpect(content().string(containsString("/admin/call-bonuses/" + ACTIVE_BONUS_ID + "/cancel")))
            .andExpect(content().string(not(containsString("/admin/call-bonuses/" + CANCELED_BONUS_ID + "/cancel"))))
            // 취소 항목은 취소 배지와 취소한 관리자, 취소 시각(KST)을 보인다
            .andExpect(content().string(containsString("취소됨")))
            .andExpect(content().string(containsString(CANCELING_ADMIN_ID.toString())))
            .andExpect(content().string(containsString("2026-10-20 12:00:00")));
    }

    @Test
    void getWithMalformedUuid_showsErrorMessage() throws Exception {
        mockMvc.perform(get("/admin/call-bonuses").with(asAdmin()).param("memberId", "abc"))
            .andExpect(status().isBadRequest())
            .andExpect(view().name("admin/error"))
            .andExpect(content().string(containsString(ErrorCode.INVALID_REQUEST.message())));

        verify(callBonusService, never()).getAll(any());
    }

    @Test
    void getWithUnknownMember_showsMemberNotFound() throws Exception {
        given(callBonusService.getAll(MEMBER_ID)).willThrow(new CustomException(ErrorCode.MEMBER_NOT_FOUND));

        mockMvc.perform(get("/admin/call-bonuses").with(asAdmin()).param("memberId", MEMBER_ID.toString()))
            .andExpect(status().isNotFound())
            .andExpect(view().name("admin/error"))
            .andExpect(content().string(containsString(ErrorCode.MEMBER_NOT_FOUND.message())));
    }

    @Test
    void grant_callsServiceWithLoggedInAdminId() throws Exception {
        mockMvc.perform(post("/admin/call-bonuses/grant")
                .with(asAdmin())
                .with(csrf())
                .param("memberId", MEMBER_ID.toString())
                .param("seconds", "600")
                .param("bonusDate", "2026-10-21")
                .param("reason", "서비스 장애 보상"))
            .andExpect(status().isFound())
            .andExpect(header().string("Location", "/admin/call-bonuses?memberId=" + MEMBER_ID));

        ArgumentCaptor<CallBonusGrantRequest> requestCaptor = forClass(CallBonusGrantRequest.class);
        verify(callBonusService).grant(eq(ADMIN_ID), eq(MEMBER_ID), requestCaptor.capture());
        assertThat(requestCaptor.getValue())
            .isEqualTo(new CallBonusGrantRequest(600, LocalDate.of(2026, 10, 21), "서비스 장애 보상"));
    }

    @Test
    void grant_withoutBonusDate_passesNullDate() throws Exception {
        mockMvc.perform(post("/admin/call-bonuses/grant")
                .with(asAdmin())
                .with(csrf())
                .param("memberId", MEMBER_ID.toString())
                .param("seconds", "60")
                .param("bonusDate", "")
                .param("reason", "테스트"))
            .andExpect(status().isFound());

        verify(callBonusService).grant(ADMIN_ID, MEMBER_ID, new CallBonusGrantRequest(60, null, "테스트"));
    }

    @Test
    void grant_withInvalidSeconds_showsValidationMessage() throws Exception {
        given(callBonusService.getAll(MEMBER_ID)).willReturn(List.of());

        for (String invalidSeconds : List.of("0", "3601")) {
            mockMvc.perform(post("/admin/call-bonuses/grant")
                    .with(asAdmin())
                    .with(csrf())
                    .param("memberId", MEMBER_ID.toString())
                    .param("seconds", invalidSeconds)
                    .param("reason", "사유"))
                .andExpect(status().isUnprocessableContent())
                .andExpect(view().name("admin/call-bonuses"))
                .andExpect(content().string(containsString("추가 통화 시간은")))
                // 입력한 값이 폼에 남는다
                .andExpect(content().string(containsString("value=\"" + invalidSeconds + "\"")))
                .andExpect(content().string(containsString("value=\"사유\"")));
        }

        verify(callBonusService, never()).grant(any(), any(), any());
    }

    @Test
    void grant_withBlankReasonAndMissingSeconds_showsBothMessages() throws Exception {
        given(callBonusService.getAll(MEMBER_ID)).willReturn(List.of());

        mockMvc.perform(post("/admin/call-bonuses/grant")
                .with(asAdmin())
                .with(csrf())
                .param("memberId", MEMBER_ID.toString())
                .param("reason", "  "))
            .andExpect(status().isUnprocessableContent())
            .andExpect(content().string(containsString("추가 통화 시간을 입력해 주세요.")))
            .andExpect(content().string(containsString("부여 사유를 입력해 주세요.")));

        verify(callBonusService, never()).grant(any(), any(), any());
    }

    @Test
    void grant_withMalformedInputs_showsErrorScreenWithoutServiceCall() throws Exception {
        mockMvc.perform(post("/admin/call-bonuses/grant")
                .with(asAdmin()).with(csrf())
                .param("memberId", "abc").param("seconds", "60").param("reason", "사유"))
            .andExpect(status().isBadRequest())
            .andExpect(view().name("admin/error"));
        mockMvc.perform(post("/admin/call-bonuses/grant")
                .with(asAdmin()).with(csrf())
                .param("memberId", MEMBER_ID.toString()).param("seconds", "60").param("reason", "사유")
                .param("bonusDate", "2026-13-45"))
            .andExpect(status().isBadRequest())
            .andExpect(view().name("admin/error"));
        mockMvc.perform(post("/admin/call-bonuses/grant")
                .with(asAdmin()).with(csrf())
                .param("seconds", "60").param("reason", "사유"))
            .andExpect(status().isBadRequest())
            .andExpect(view().name("admin/error"));

        verify(callBonusService, never()).grant(any(), any(), any());
    }

    @Test
    void grant_whenServiceRejects_showsErrorScreen() throws Exception {
        given(callBonusService.grant(eq(ADMIN_ID), eq(MEMBER_ID), any()))
            .willThrow(new CustomException(ErrorCode.MEMBER_NOT_FOUND));

        mockMvc.perform(post("/admin/call-bonuses/grant")
                .with(asAdmin()).with(csrf())
                .param("memberId", MEMBER_ID.toString()).param("seconds", "60").param("reason", "사유"))
            .andExpect(status().isNotFound())
            .andExpect(view().name("admin/error"))
            .andExpect(content().string(containsString(ErrorCode.MEMBER_NOT_FOUND.message())));
    }

    @Test
    void cancel_callsServiceWithLoggedInAdminId() throws Exception {
        mockMvc.perform(post("/admin/call-bonuses/{callBonusId}/cancel", ACTIVE_BONUS_ID)
                .with(asAdmin())
                .with(csrf())
                .param("memberId", MEMBER_ID.toString()))
            .andExpect(status().isFound())
            .andExpect(header().string("Location", "/admin/call-bonuses?memberId=" + MEMBER_ID));

        verify(callBonusService).cancel(ADMIN_ID, MEMBER_ID, ACTIVE_BONUS_ID);
    }

    @Test
    void cancel_withMalformedCallBonusId_showsErrorScreen() throws Exception {
        mockMvc.perform(post("/admin/call-bonuses/{callBonusId}/cancel", "abc")
                .with(asAdmin())
                .with(csrf())
                .param("memberId", MEMBER_ID.toString()))
            .andExpect(status().isBadRequest())
            .andExpect(view().name("admin/error"));

        verify(callBonusService, never()).cancel(any(), any(), any());
    }

    @Test
    void cancel_whenBonusNotFound_showsErrorScreen() throws Exception {
        doThrow(new CustomException(ErrorCode.CALL_BONUS_NOT_FOUND))
            .when(callBonusService).cancel(ADMIN_ID, MEMBER_ID, ACTIVE_BONUS_ID);

        mockMvc.perform(post("/admin/call-bonuses/{callBonusId}/cancel", ACTIVE_BONUS_ID)
                .with(asAdmin())
                .with(csrf())
                .param("memberId", MEMBER_ID.toString()))
            .andExpect(status().isNotFound())
            .andExpect(content().string(containsString(ErrorCode.CALL_BONUS_NOT_FOUND.message())));
    }

    @Test
    void postWithWrongCsrf_returns403() throws Exception {
        given(callBonusService.getAll(MEMBER_ID)).willReturn(List.of());
        // 부여 폼을 렌더링하면 CSRF 토큰이 세션에 저장된다
        MockHttpSession session = (MockHttpSession) mockMvc.perform(
                get("/admin/call-bonuses").with(asAdmin()).param("memberId", MEMBER_ID.toString()))
            .andReturn().getRequest().getSession(false);

        mockMvc.perform(post("/admin/call-bonuses/grant")
                .session(session)
                .with(asAdmin())
                .param("_csrf", "wrong-token")
                .param("memberId", MEMBER_ID.toString())
                .param("seconds", "60")
                .param("reason", "사유"))
            .andExpect(status().isForbidden());

        verify(callBonusService, never()).grant(any(), any(), any());
    }

    @Test
    void postWithoutSession_redirectsToLogin() throws Exception {
        mockMvc.perform(post("/admin/call-bonuses/grant")
                .param("memberId", MEMBER_ID.toString())
                .param("seconds", "60")
                .param("reason", "사유"))
            .andExpect(status().isFound())
            .andExpect(header().string("Location", endsWith("/admin/login")));

        verify(callBonusService, never()).grant(any(), any(), any());
    }

    @Test
    void getWithoutSession_redirectsToLogin() throws Exception {
        mockMvc.perform(get("/admin/call-bonuses"))
            .andExpect(status().isFound())
            .andExpect(header().string("Location", endsWith("/admin/login")));
    }

    private CallBonusResponse activeBonus() {
        return new CallBonusResponse(ACTIVE_BONUS_ID, MEMBER_ID, LocalDate.of(2026, 10, 21), 600, "서비스 장애 보상",
            ADMIN_ID, false, null, null, Instant.parse("2026-10-20T01:00:00Z"));
    }

    private CallBonusResponse canceledBonus() {
        return new CallBonusResponse(CANCELED_BONUS_ID, MEMBER_ID, LocalDate.of(2026, 10, 20), 300, "중복 부여",
            ADMIN_ID, true, Instant.parse("2026-10-20T03:00:00Z"), CANCELING_ADMIN_ID,
            Instant.parse("2026-10-19T01:00:00Z"));
    }

}
