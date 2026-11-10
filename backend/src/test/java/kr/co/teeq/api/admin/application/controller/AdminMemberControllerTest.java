package kr.co.teeq.api.admin.application.controller;

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
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.admin.infrastructure.config.AdminSecurityConfig;
import kr.co.teeq.api.admin.support.AdminSliceTestConfig;
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

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AdminRepository adminRepository;

    @MockitoBean
    private MemberQueryService memberQueryService;

    @MockitoBean
    private MemberDeletionService memberDeletionService;

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

}
