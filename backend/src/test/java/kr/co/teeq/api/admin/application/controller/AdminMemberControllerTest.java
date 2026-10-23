package kr.co.teeq.api.admin.application.controller;

import static kr.co.teeq.api.admin.support.AdminTestAuthentication.ADMIN_ID;
import static kr.co.teeq.api.admin.support.AdminTestAuthentication.asAdmin;
import static kr.co.teeq.api.admin.support.AdminTestAuthentication.asSuperAdmin;
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
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.model;
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
import kr.co.teeq.api.member.application.dto.request.MemberSearchRequest;
import kr.co.teeq.api.member.application.dto.response.MemberPageResponse;
import kr.co.teeq.api.member.application.dto.response.MemberSummaryResponse;
import kr.co.teeq.api.member.application.service.MemberDeletionService;
import kr.co.teeq.api.member.application.service.MemberQueryService;
import kr.co.teeq.api.member.core.constant.LoginType;
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

@WebMvcTest(controllers = AdminMemberController.class)
@ActiveProfiles("test")
@Import({
    AdminSecurityConfig.class,
    AdminSliceTestConfig.class,
    GlobalExceptionHandler.class,
    AdminExceptionHandler.class,
    AdminMemberController.class
})
class AdminMemberControllerTest {

    private static final String PATH = "/admin/members";
    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");
    private static final UUID OTHER_MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5c");
    private static final UUID ACTIVE_BONUS_ID = UUID.fromString("0199aaaa-0000-7000-8000-000000000001");
    private static final UUID CANCELED_BONUS_ID = UUID.fromString("0199aaaa-0000-7000-8000-000000000002");
    private static final UUID CANCELING_ADMIN_ID = UUID.fromString("0199bbbb-0000-7000-8000-000000000003");
    private static final String DELETE_FORM_ACTION = "action=\"/admin/members/" + MEMBER_ID + "/delete\"";

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AdminRepository adminRepository;

    @MockitoBean
    private MemberQueryService memberQueryService;

    @MockitoBean
    private MemberDeletionService memberDeletionService;

    @MockitoBean
    private CallBonusService callBonusService;

    @Test
    void members_defaultRequest_rendersFirstPageOf20() throws Exception {
        given(memberQueryService.search(any(), any())).willReturn(pageOf(List.of(completeMember(), otherMember()),
            0, 20, 2));

        mockMvc.perform(get(PATH).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(view().name("admin/members"))
            .andExpect(model().attributeExists("result"))
            .andExpect(content().string(containsString("foo@example.com")))
            .andExpect(content().string(containsString("테스터")))
            .andExpect(content().string(containsString("bar@example.com")))
            .andExpect(content().string(containsString("href=\"/admin/members/" + MEMBER_ID + "\"")))
            // 사이드바의 회원 관리 메뉴가 강조된다
            .andExpect(content().string(containsString("class=\"active\"")));

        ArgumentCaptor<Pageable> pageable = forClass(Pageable.class);
        verify(memberQueryService).search(eq(new MemberSearchRequest(null, null)), pageable.capture());
        assertThat(pageable.getValue().getPageNumber()).isZero();
        assertThat(pageable.getValue().getPageSize()).isEqualTo(20);
    }

    @Test
    void members_withFilters_passesSearchRequestAndKeepsFilterInForm() throws Exception {
        given(memberQueryService.search(any(), any())).willReturn(pageOf(List.of(), 0, 20, 0));

        mockMvc.perform(get(PATH).with(asAdmin())
                .param("keyword", "foo").param("loginType", "APPLE"))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("value=\"foo\"")))
            .andExpect(content().string(containsString("회원이 없습니다.")));

        verify(memberQueryService).search(eq(new MemberSearchRequest("foo", LoginType.APPLE)), any());
    }

    @Test
    void members_withMalformedLoginType_showsErrorScreen() throws Exception {
        mockMvc.perform(get(PATH).with(asAdmin()).param("loginType", "KAKAO"))
            .andExpect(status().isBadRequest())
            .andExpect(view().name("admin/error"));

        verify(memberQueryService, never()).search(any(), any());
    }

    @Test
    void members_middlePage_rendersPaginationLinksKeepingFilters() throws Exception {
        given(memberQueryService.search(any(), any())).willReturn(pageOf(List.of(completeMember()), 1, 1, 3));

        mockMvc.perform(get(PATH).with(asAdmin()).param("keyword", "foo").param("page", "1").param("size", "1"))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("2 / 3")))
            .andExpect(content().string(containsString("/admin/members?keyword=foo&amp;page=0&amp;size=1")))
            .andExpect(content().string(containsString("/admin/members?keyword=foo&amp;page=2&amp;size=1")));
    }

    @Test
    void members_withDeletedNotice_showsNotice() throws Exception {
        given(memberQueryService.search(any(), any())).willReturn(pageOf(List.of(), 0, 20, 0));

        mockMvc.perform(get(PATH).with(asAdmin()).param("deleted", "true"))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("회원을 삭제했습니다.")));
        mockMvc.perform(get(PATH).with(asAdmin()))
            .andExpect(content().string(not(containsString("회원을 삭제했습니다."))));
    }

    @Test
    void detail_existingMember_rendersDetailWithBonuses() throws Exception {
        givenMemberWithBonuses();

        mockMvc.perform(get(PATH + "/{memberId}", MEMBER_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(view().name("admin/member-detail"))
            .andExpect(content().string(containsString("foo@example.com")))
            .andExpect(content().string(containsString("서비스 장애 보상")))
            .andExpect(content().string(containsString("중복 부여")))
            .andExpect(content().string(containsString("/admin/call-usages?memberId=" + MEMBER_ID)))
            // 부여 폼과 취소 버튼은 회원 상세 하위 경로를 쓴다
            .andExpect(content().string(containsString("/admin/members/" + MEMBER_ID + "/call-bonuses/grant")))
            .andExpect(content().string(containsString("name=\"_csrf\"")))
            .andExpect(content().string(containsString(
                "/admin/members/" + MEMBER_ID + "/call-bonuses/" + ACTIVE_BONUS_ID + "/cancel")))
            .andExpect(content().string(not(containsString("/call-bonuses/" + CANCELED_BONUS_ID + "/cancel"))))
            .andExpect(content().string(containsString("취소됨")))
            .andExpect(content().string(containsString(CANCELING_ADMIN_ID.toString())))
            .andExpect(content().string(containsString("2026-10-20 12:00:00")));
    }

    @Test
    void detail_missingMember_rendersNotFoundError() throws Exception {
        given(memberQueryService.getSummary(MEMBER_ID)).willThrow(new CustomException(ErrorCode.MEMBER_NOT_FOUND));

        mockMvc.perform(get(PATH + "/{memberId}", MEMBER_ID).with(asAdmin()))
            .andExpect(status().isNotFound())
            .andExpect(view().name("admin/error"))
            .andExpect(content().string(containsString(ErrorCode.MEMBER_NOT_FOUND.message())));
    }

    @Test
    void detail_withMalformedMemberId_showsErrorScreen() throws Exception {
        mockMvc.perform(get(PATH + "/{memberId}", "abc").with(asAdmin()))
            .andExpect(status().isBadRequest())
            .andExpect(view().name("admin/error"));
    }

    @Test
    void detail_showsDeleteFormOnlyForSuperAdmin() throws Exception {
        givenMemberWithBonuses();

        mockMvc.perform(get(PATH + "/{memberId}", MEMBER_ID).with(asSuperAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("<dialog")))
            .andExpect(content().string(containsString(DELETE_FORM_ACTION)));
        mockMvc.perform(get(PATH + "/{memberId}", MEMBER_ID).with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(not(containsString("<dialog"))))
            .andExpect(content().string(not(containsString("/delete"))));
    }

    @Test
    void grantBonus_validRequest_redirectsToDetail() throws Exception {
        mockMvc.perform(post(PATH + "/{memberId}/call-bonuses/grant", MEMBER_ID)
                .with(asAdmin()).with(csrf())
                .param("seconds", "600").param("bonusDate", "2026-10-21").param("reason", "서비스 장애 보상"))
            .andExpect(status().isFound())
            .andExpect(header().string("Location", PATH + "/" + MEMBER_ID));

        ArgumentCaptor<CallBonusGrantRequest> request = forClass(CallBonusGrantRequest.class);
        verify(callBonusService).grant(eq(ADMIN_ID), eq(MEMBER_ID), request.capture());
        assertThat(request.getValue())
            .isEqualTo(new CallBonusGrantRequest(600, LocalDate.of(2026, 10, 21), "서비스 장애 보상"));
    }

    @Test
    void grantBonus_withoutBonusDate_passesNullDate() throws Exception {
        mockMvc.perform(post(PATH + "/{memberId}/call-bonuses/grant", MEMBER_ID)
                .with(asAdmin()).with(csrf())
                .param("seconds", "60").param("bonusDate", "").param("reason", "테스트"))
            .andExpect(status().isFound());

        verify(callBonusService).grant(ADMIN_ID, MEMBER_ID, new CallBonusGrantRequest(60, null, "테스트"));
    }

    @Test
    void grantBonus_invalidSeconds_returns422WithFormErrors() throws Exception {
        givenMemberWithBonuses();

        for (String invalidSeconds : List.of("0", "3601")) {
            mockMvc.perform(post(PATH + "/{memberId}/call-bonuses/grant", MEMBER_ID)
                    .with(asAdmin()).with(csrf())
                    .param("seconds", invalidSeconds).param("reason", "사유"))
                .andExpect(status().isUnprocessableContent())
                .andExpect(view().name("admin/member-detail"))
                .andExpect(content().string(containsString("추가 통화 시간은")))
                .andExpect(content().string(containsString("value=\"" + invalidSeconds + "\"")))
                .andExpect(content().string(containsString("value=\"사유\"")))
                .andExpect(content().string(containsString("foo@example.com")));
        }

        verify(callBonusService, never()).grant(any(), any(), any());
    }

    @Test
    void grantBonus_blankReasonAndMissingSeconds_showsBothMessages() throws Exception {
        givenMemberWithBonuses();

        mockMvc.perform(post(PATH + "/{memberId}/call-bonuses/grant", MEMBER_ID)
                .with(asAdmin()).with(csrf())
                .param("reason", "  "))
            .andExpect(status().isUnprocessableContent())
            .andExpect(content().string(containsString("추가 통화 시간을 입력해 주세요.")))
            .andExpect(content().string(containsString("부여 사유를 입력해 주세요.")));
    }

    @Test
    void grantBonus_whenServiceRejects_showsErrorScreen() throws Exception {
        given(callBonusService.grant(eq(ADMIN_ID), eq(MEMBER_ID), any()))
            .willThrow(new CustomException(ErrorCode.MEMBER_NOT_FOUND));

        mockMvc.perform(post(PATH + "/{memberId}/call-bonuses/grant", MEMBER_ID)
                .with(asAdmin()).with(csrf())
                .param("seconds", "60").param("reason", "사유"))
            .andExpect(status().isNotFound())
            .andExpect(view().name("admin/error"));
    }

    @Test
    void cancelBonus_redirectsToDetail() throws Exception {
        mockMvc.perform(post(PATH + "/{memberId}/call-bonuses/{callBonusId}/cancel", MEMBER_ID, ACTIVE_BONUS_ID)
                .with(asAdmin()).with(csrf()))
            .andExpect(status().isFound())
            .andExpect(header().string("Location", PATH + "/" + MEMBER_ID));

        verify(callBonusService).cancel(ADMIN_ID, MEMBER_ID, ACTIVE_BONUS_ID);
    }

    @Test
    void cancelBonus_whenBonusNotFound_showsErrorScreen() throws Exception {
        doThrow(new CustomException(ErrorCode.CALL_BONUS_NOT_FOUND))
            .when(callBonusService).cancel(ADMIN_ID, MEMBER_ID, ACTIVE_BONUS_ID);

        mockMvc.perform(post(PATH + "/{memberId}/call-bonuses/{callBonusId}/cancel", MEMBER_ID, ACTIVE_BONUS_ID)
                .with(asAdmin()).with(csrf()))
            .andExpect(status().isNotFound())
            .andExpect(content().string(containsString(ErrorCode.CALL_BONUS_NOT_FOUND.message())));
    }

    @Test
    void grantBonus_withWrongCsrfToken_isForbidden() throws Exception {
        mockMvc.perform(post(PATH + "/{memberId}/call-bonuses/grant", MEMBER_ID)
                .with(asAdmin()).with(csrf().useInvalidToken())
                .param("seconds", "60").param("reason", "사유"))
            .andExpect(status().isForbidden());

        verify(callBonusService, never()).grant(any(), any(), any());
    }

    @Test
    void cancelBonus_withWrongCsrfToken_isForbidden() throws Exception {
        mockMvc.perform(post(PATH + "/{memberId}/call-bonuses/{callBonusId}/cancel", MEMBER_ID, ACTIVE_BONUS_ID)
                .with(asAdmin()).with(csrf().useInvalidToken()))
            .andExpect(status().isForbidden());

        verify(callBonusService, never()).cancel(any(), any(), any());
    }

    @Test
    void cancelBonus_withMalformedCallBonusId_showsErrorScreen() throws Exception {
        mockMvc.perform(post(PATH + "/{memberId}/call-bonuses/{callBonusId}/cancel", MEMBER_ID, "abc")
                .with(asAdmin()).with(csrf()))
            .andExpect(status().isBadRequest())
            .andExpect(view().name("admin/error"));

        verify(callBonusService, never()).cancel(any(), any(), any());
    }

    @Test
    void delete_success_redirectsToListWithNotice() throws Exception {
        mockMvc.perform(post(PATH + "/{memberId}/delete", MEMBER_ID).with(asSuperAdmin()).with(csrf()))
            .andExpect(status().isFound())
            .andExpect(header().string("Location", PATH + "?deleted=true"));

        verify(memberDeletionService).delete(MEMBER_ID);
    }

    @Test
    void delete_activeCall_rendersErrorPage409() throws Exception {
        doThrow(new CustomException(ErrorCode.MEMBER_HAS_ACTIVE_CALL)).when(memberDeletionService).delete(MEMBER_ID);

        mockMvc.perform(post(PATH + "/{memberId}/delete", MEMBER_ID).with(asSuperAdmin()).with(csrf()))
            .andExpect(status().isConflict())
            .andExpect(view().name("admin/error"))
            .andExpect(content().string(containsString(ErrorCode.MEMBER_HAS_ACTIVE_CALL.message())));
    }

    @Test
    void delete_asAdmin_isForbiddenAndDoesNotDelete() throws Exception {
        mockMvc.perform(post(PATH + "/{memberId}/delete", MEMBER_ID).with(asAdmin()).with(csrf()))
            .andExpect(status().isForbidden());

        verify(memberDeletionService, never()).delete(any());
    }

    @Test
    void withoutSession_redirectsToLogin() throws Exception {
        mockMvc.perform(get(PATH))
            .andExpect(status().isFound())
            .andExpect(header().string("Location", endsWith("/admin/login")));
        mockMvc.perform(post(PATH + "/{memberId}/delete", MEMBER_ID))
            .andExpect(status().isFound())
            .andExpect(header().string("Location", endsWith("/admin/login")));

        verify(memberDeletionService, never()).delete(any());
    }

    private void givenMemberWithBonuses() {
        given(memberQueryService.getSummary(MEMBER_ID)).willReturn(completeMember());
        given(callBonusService.getAll(MEMBER_ID)).willReturn(List.of(activeBonus(), canceledBonus()));
    }

    private MemberPageResponse pageOf(List<MemberSummaryResponse> members, int page, int size, long totalElements) {
        return new MemberPageResponse(members, page, size, totalElements);
    }

    private MemberSummaryResponse completeMember() {
        return new MemberSummaryResponse(MEMBER_ID, "테스터", "foo@example.com", LoginType.GOOGLE,
            Instant.parse("2026-10-20T03:00:00Z"));
    }

    private MemberSummaryResponse otherMember() {
        return new MemberSummaryResponse(OTHER_MEMBER_ID, "다른회원", "bar@example.com", LoginType.APPLE,
            Instant.parse("2026-10-21T03:00:00Z"));
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
