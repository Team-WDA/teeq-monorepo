package kr.co.teeq.api.admin.application.controller;

import static kr.co.teeq.api.admin.support.AdminTestAuthentication.ADMIN_ID;
import static kr.co.teeq.api.admin.support.AdminTestAuthentication.SUPER_ADMIN_ID;
import static kr.co.teeq.api.admin.support.AdminTestAuthentication.asAdmin;
import static kr.co.teeq.api.admin.support.AdminTestAuthentication.asSuperAdmin;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.matchesPattern;
import static org.hamcrest.Matchers.not;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.willThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.redirectedUrl;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.view;

import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.admin.application.dto.request.AdminAccountCreateRequest;
import kr.co.teeq.api.admin.application.dto.response.AdminAccountResponse;
import kr.co.teeq.api.admin.application.service.AdminAccountService;
import kr.co.teeq.api.admin.infrastructure.config.AdminSecurityConfig;
import kr.co.teeq.api.admin.support.AdminSliceTestConfig;
import kr.co.teeq.api.common.application.exception.GlobalExceptionHandler;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.constant.AdminRole;
import kr.co.teeq.api.member.core.repository.AdminRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(controllers = AdminAccountController.class)
@ActiveProfiles("test")
@Import({
    AdminSecurityConfig.class,
    AdminSliceTestConfig.class,
    GlobalExceptionHandler.class,
    AdminExceptionHandler.class,
    AdminAccountController.class
})
class AdminAccountControllerTest {

    private static final UUID TARGET_ID = UUID.fromString("0199f5a0-3e4f-7a50-8c6d-7e8f9a0b1c2d");
    private static final String VALID_PASSWORD = "Valid1234!";
    private static final String WEAK_PASSWORD = "weakpw";

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AdminRepository adminRepository;

    @MockitoBean
    private AdminAccountService adminAccountService;

    @Test
    void getAccounts_asSuperAdmin_rendersRowsWithoutDeactivateFormForSelf() throws Exception {
        given(adminAccountService.getAll()).willReturn(List.of(
            new AdminAccountResponse(SUPER_ADMIN_ID, "owner", "최고 관리자", AdminRole.SUPER_ADMIN,
                AdminSliceTestConfig.NOW),
            new AdminAccountResponse(TARGET_ID, "operator2", "운영자2", AdminRole.ADMIN, AdminSliceTestConfig.NOW)));

        mockMvc.perform(get("/admin/accounts").with(asSuperAdmin()))
            .andExpect(status().isOk())
            .andExpect(view().name("admin/accounts"))
            .andExpect(content().string(containsString("owner")))
            .andExpect(content().string(containsString("operator2")))
            // 시각은 KST로 표시한다
            .andExpect(content().string(containsString("2026-10-20 12:00:00")))
            .andExpect(content().string(containsString("/admin/accounts/" + TARGET_ID + "/deactivate")))
            .andExpect(content().string(not(containsString("/admin/accounts/" + SUPER_ADMIN_ID + "/deactivate"))))
            .andExpect(content().string(not(containsString("/admin/accounts/" + SUPER_ADMIN_ID + "/role"))))
            .andExpect(content().string(not(containsString("/admin/accounts/" + SUPER_ADMIN_ID + "/password"))))
            .andExpect(content().string(containsString("name=\"_csrf\"")));
    }

    @Test
    void getAccounts_createFormDefaultsToAdminRole() throws Exception {
        given(adminAccountService.getAll()).willReturn(List.of());

        // 선택 없이 "추가"를 눌러도 SUPER_ADMIN이 만들어지지 않도록 ADMIN이 기본 선택이어야 한다
        mockMvc.perform(get("/admin/accounts").with(asSuperAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(matchesPattern("(?s).*<option[^>]*value=\"ADMIN\"[^>]*selected.*")))
            .andExpect(content().string(not(matchesPattern(
                "(?s).*<option[^>]*value=\"SUPER_ADMIN\"[^>]*selected.*"))));
    }

    @Test
    void getAccounts_asAdmin_isForbidden() throws Exception {
        mockMvc.perform(get("/admin/accounts").with(asAdmin()))
            .andExpect(status().isForbidden())
            .andExpect(jsonPath("$.errorCode").value("ACCESS_DENIED"));

        verifyNoInteractions(adminAccountService);
    }

    @Test
    void getAccounts_withoutSession_redirectsToLogin() throws Exception {
        mockMvc.perform(get("/admin/accounts"))
            .andExpect(status().isFound())
            .andExpect(header().string("Location", containsString("/admin/login")));
    }

    @Test
    void create_withValidValues_callsServiceAndRedirects() throws Exception {
        mockMvc.perform(post("/admin/accounts").with(asSuperAdmin()).with(csrf())
                .param("username", "new.admin")
                .param("password", VALID_PASSWORD)
                .param("name", "새 관리자")
                .param("role", "ADMIN"))
            .andExpect(status().isFound())
            .andExpect(redirectedUrl("/admin/accounts"));

        verify(adminAccountService).create(SUPER_ADMIN_ID,
            new AdminAccountCreateRequest("new.admin", VALID_PASSWORD, "새 관리자", AdminRole.ADMIN));
    }

    @Test
    void create_withInvalidUsername_rendersFormWithoutEchoingPassword() throws Exception {
        given(adminAccountService.getAll()).willReturn(List.of());

        mockMvc.perform(post("/admin/accounts").with(asSuperAdmin()).with(csrf())
                .param("username", "ab")
                .param("password", VALID_PASSWORD)
                .param("name", "새 관리자")
                .param("role", "ADMIN"))
            .andExpect(status().isUnprocessableContent())
            .andExpect(view().name("admin/accounts"))
            .andExpect(content().string(containsString("아이디는 영문, 숫자, 점, 밑줄, 하이픈으로 3~30자여야 합니다.")))
            // 비밀번호를 뺀 입력값만 남긴다
            .andExpect(content().string(containsString("value=\"ab\"")))
            .andExpect(content().string(containsString("value=\"새 관리자\"")))
            .andExpect(content().string(not(containsString(VALID_PASSWORD))));

        verify(adminAccountService, never()).create(any(), any());
    }

    @Test
    void create_withoutRole_rendersRoleError() throws Exception {
        given(adminAccountService.getAll()).willReturn(List.of());

        mockMvc.perform(post("/admin/accounts").with(asSuperAdmin()).with(csrf())
                .param("username", "new.admin")
                .param("password", VALID_PASSWORD)
                .param("name", "새 관리자"))
            .andExpect(status().isUnprocessableContent())
            .andExpect(content().string(containsString("권한을 선택해 주세요.")));
    }

    @Test
    void create_withDuplicateUsername_showsConflictMessage() throws Exception {
        given(adminAccountService.create(any(), any()))
            .willThrow(new CustomException(ErrorCode.DUPLICATE_ADMIN_USERNAME));

        mockMvc.perform(post("/admin/accounts").with(asSuperAdmin()).with(csrf())
                .param("username", "new.admin")
                .param("password", VALID_PASSWORD)
                .param("name", "새 관리자")
                .param("role", "ADMIN"))
            .andExpect(status().isConflict())
            .andExpect(content().string(containsString(ErrorCode.DUPLICATE_ADMIN_USERNAME.message())));
    }

    @Test
    void create_withWrongCsrf_isForbidden() throws Exception {
        given(adminAccountService.getAll()).willReturn(List.of());
        // 화면을 렌더링하면 CSRF 토큰이 세션에 저장된다
        MockHttpSession session = (MockHttpSession) mockMvc.perform(get("/admin/accounts").with(asSuperAdmin()))
            .andReturn().getRequest().getSession(false);

        mockMvc.perform(post("/admin/accounts").session(session).with(asSuperAdmin())
                .param("_csrf", "wrong-token")
                .param("username", "new.admin")
                .param("password", VALID_PASSWORD)
                .param("name", "새 관리자")
                .param("role", "ADMIN"))
            .andExpect(status().isForbidden());

        verify(adminAccountService, never()).create(any(), any());
    }

    @Test
    void create_asAdmin_isForbidden() throws Exception {
        mockMvc.perform(post("/admin/accounts").with(asAdmin()).with(csrf())
                .param("username", "new.admin")
                .param("password", VALID_PASSWORD)
                .param("name", "새 관리자")
                .param("role", "ADMIN"))
            .andExpect(status().isForbidden());

        verifyNoInteractions(adminAccountService);
    }

    @Test
    void changeRole_callsServiceAndRedirects() throws Exception {
        mockMvc.perform(post("/admin/accounts/{adminId}/role", TARGET_ID).with(asSuperAdmin()).with(csrf())
                .param("role", "SUPER_ADMIN"))
            .andExpect(status().isFound())
            .andExpect(redirectedUrl("/admin/accounts"));

        verify(adminAccountService).changeRole(SUPER_ADMIN_ID, TARGET_ID, AdminRole.SUPER_ADMIN);
    }

    @Test
    void changeRole_whenLastSuperAdmin_showsProtectionMessage() throws Exception {
        willThrow(new CustomException(ErrorCode.LAST_SUPER_ADMIN_PROTECTED))
            .given(adminAccountService).changeRole(any(), any(), any());

        mockMvc.perform(post("/admin/accounts/{adminId}/role", TARGET_ID).with(asSuperAdmin()).with(csrf())
                .param("role", "ADMIN"))
            .andExpect(status().isConflict())
            .andExpect(content().string(containsString(ErrorCode.LAST_SUPER_ADMIN_PROTECTED.message())));
    }

    @Test
    void deactivate_callsServiceAndRedirects() throws Exception {
        mockMvc.perform(post("/admin/accounts/{adminId}/deactivate", TARGET_ID).with(asSuperAdmin()).with(csrf()))
            .andExpect(status().isFound())
            .andExpect(redirectedUrl("/admin/accounts"));

        verify(adminAccountService).deactivate(SUPER_ADMIN_ID, TARGET_ID);
    }

    @Test
    void deactivate_whenLastSuperAdmin_showsProtectionMessage() throws Exception {
        willThrow(new CustomException(ErrorCode.LAST_SUPER_ADMIN_PROTECTED))
            .given(adminAccountService).deactivate(any(), any());

        mockMvc.perform(post("/admin/accounts/{adminId}/deactivate", TARGET_ID).with(asSuperAdmin()).with(csrf()))
            .andExpect(status().isConflict())
            .andExpect(content().string(containsString(ErrorCode.LAST_SUPER_ADMIN_PROTECTED.message())));
    }

    @Test
    void resetPassword_callsServiceAndRedirects() throws Exception {
        mockMvc.perform(post("/admin/accounts/{adminId}/password", TARGET_ID).with(asSuperAdmin()).with(csrf())
                .param("newPassword", VALID_PASSWORD))
            .andExpect(status().isFound())
            .andExpect(redirectedUrl("/admin/accounts"));

        verify(adminAccountService).resetPassword(SUPER_ADMIN_ID, TARGET_ID, VALID_PASSWORD);
    }

    @Test
    void resetPassword_withWeakPassword_rendersErrorWithoutEchoingInput() throws Exception {
        given(adminAccountService.getAll()).willReturn(List.of());

        mockMvc.perform(post("/admin/accounts/{adminId}/password", TARGET_ID).with(asSuperAdmin()).with(csrf())
                .param("newPassword", WEAK_PASSWORD))
            .andExpect(status().isUnprocessableContent())
            .andExpect(view().name("admin/accounts"))
            .andExpect(content().string(containsString("비밀번호")))
            .andExpect(content().string(not(containsString(WEAK_PASSWORD))));

        verify(adminAccountService, never()).resetPassword(any(), any(), anyString());
    }

    @Test
    void resetPassword_withMissingTarget_showsNotFoundMessage() throws Exception {
        willThrow(new CustomException(ErrorCode.ADMIN_NOT_FOUND))
            .given(adminAccountService).resetPassword(any(), any(), anyString());

        mockMvc.perform(post("/admin/accounts/{adminId}/password", TARGET_ID).with(asSuperAdmin()).with(csrf())
                .param("newPassword", VALID_PASSWORD))
            .andExpect(status().is(ErrorCode.ADMIN_NOT_FOUND.httpStatus()))
            .andExpect(content().string(containsString(ErrorCode.ADMIN_NOT_FOUND.message())));
    }

    @Test
    void resetPassword_asAdmin_isForbidden() throws Exception {
        mockMvc.perform(post("/admin/accounts/{adminId}/password", ADMIN_ID).with(asAdmin()).with(csrf())
                .param("newPassword", VALID_PASSWORD))
            .andExpect(status().isForbidden());

        verifyNoInteractions(adminAccountService);
    }

}
