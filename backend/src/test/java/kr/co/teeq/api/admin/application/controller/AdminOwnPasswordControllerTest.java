package kr.co.teeq.api.admin.application.controller;

import static kr.co.teeq.api.admin.support.AdminTestAuthentication.ADMIN_ID;
import static kr.co.teeq.api.admin.support.AdminTestAuthentication.asAdmin;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.BDDMockito.willThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.redirectedUrl;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.view;

import kr.co.teeq.api.admin.application.service.AdminAccountService;
import kr.co.teeq.api.admin.infrastructure.config.AdminSecurityConfig;
import kr.co.teeq.api.admin.support.AdminSliceTestConfig;
import kr.co.teeq.api.common.application.exception.GlobalExceptionHandler;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.repository.AdminRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(controllers = AdminOwnPasswordController.class)
@ActiveProfiles("test")
@Import({
    AdminSecurityConfig.class,
    AdminSliceTestConfig.class,
    GlobalExceptionHandler.class,
    AdminExceptionHandler.class,
    AdminOwnPasswordController.class
})
class AdminOwnPasswordControllerTest {

    private static final String CURRENT_PASSWORD = "Current1234!";
    private static final String NEW_PASSWORD = "Brandnew1234!";

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AdminRepository adminRepository;

    @MockitoBean
    private AdminAccountService adminAccountService;

    @Test
    void getPassword_asAdmin_rendersForm() throws Exception {
        mockMvc.perform(get("/admin/password").with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(view().name("admin/own-password"))
            .andExpect(content().string(containsString("name=\"currentPassword\"")))
            .andExpect(content().string(containsString("name=\"_csrf\"")))
            .andExpect(content().string(not(containsString("비밀번호를 변경했습니다."))));
    }

    @Test
    void getPassword_afterChange_showsCompletionNotice() throws Exception {
        mockMvc.perform(get("/admin/password").param("changed", "").with(asAdmin()))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("비밀번호를 변경했습니다.")));
    }

    @Test
    void change_withMismatchedConfirmation_rendersErrorWithoutCallingService() throws Exception {
        mockMvc.perform(post("/admin/password").with(asAdmin()).with(csrf())
                .param("currentPassword", CURRENT_PASSWORD)
                .param("newPassword", NEW_PASSWORD)
                .param("newPasswordConfirm", "Different1234!"))
            .andExpect(status().isUnprocessableContent())
            .andExpect(view().name("admin/own-password"))
            .andExpect(content().string(containsString("새 비밀번호와 확인 값이 일치하지 않습니다.")))
            .andExpect(content().string(not(containsString(CURRENT_PASSWORD))))
            .andExpect(content().string(not(containsString(NEW_PASSWORD))));

        verifyNoInteractions(adminAccountService);
    }

    @Test
    void change_withWeakNewPassword_rendersRuleMessage() throws Exception {
        mockMvc.perform(post("/admin/password").with(asAdmin()).with(csrf())
                .param("currentPassword", CURRENT_PASSWORD)
                .param("newPassword", "weakpw")
                .param("newPasswordConfirm", "weakpw"))
            .andExpect(status().isUnprocessableContent())
            .andExpect(content().string(containsString("비밀번호")))
            .andExpect(content().string(not(containsString("weakpw"))));

        verify(adminAccountService, never()).changeOwnPassword(any(), anyString(), anyString());
    }

    @Test
    void change_withValidValues_callsServiceAndRedirects() throws Exception {
        mockMvc.perform(post("/admin/password").with(asAdmin()).with(csrf())
                .param("currentPassword", CURRENT_PASSWORD)
                .param("newPassword", NEW_PASSWORD)
                .param("newPasswordConfirm", NEW_PASSWORD))
            .andExpect(status().isFound())
            .andExpect(redirectedUrl("/admin/password?changed"));

        verify(adminAccountService).changeOwnPassword(ADMIN_ID, CURRENT_PASSWORD, NEW_PASSWORD);
    }

    @Test
    void change_withWrongCurrentPassword_rendersMessageWithoutEchoingInput() throws Exception {
        willThrow(new CustomException(ErrorCode.INVALID_CURRENT_PASSWORD))
            .given(adminAccountService).changeOwnPassword(any(), anyString(), anyString());

        mockMvc.perform(post("/admin/password").with(asAdmin()).with(csrf())
                .param("currentPassword", CURRENT_PASSWORD)
                .param("newPassword", NEW_PASSWORD)
                .param("newPasswordConfirm", NEW_PASSWORD))
            .andExpect(status().isUnprocessableContent())
            .andExpect(view().name("admin/own-password"))
            .andExpect(content().string(containsString(ErrorCode.INVALID_CURRENT_PASSWORD.message())))
            .andExpect(content().string(not(containsString(CURRENT_PASSWORD))))
            .andExpect(content().string(not(containsString(NEW_PASSWORD))));
    }

    @Test
    void change_withWrongCsrf_isForbidden() throws Exception {
        // 화면을 렌더링하면 CSRF 토큰이 세션에 저장된다
        MockHttpSession session = (MockHttpSession) mockMvc.perform(get("/admin/password").with(asAdmin()))
            .andReturn().getRequest().getSession(false);

        mockMvc.perform(post("/admin/password").session(session).with(asAdmin())
                .param("_csrf", "wrong-token")
                .param("currentPassword", CURRENT_PASSWORD)
                .param("newPassword", NEW_PASSWORD)
                .param("newPasswordConfirm", NEW_PASSWORD))
            .andExpect(status().isForbidden());

        verifyNoInteractions(adminAccountService);
    }

}
